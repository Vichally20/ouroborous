import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/game/story_engine.dart';
import 'package:ouroboros/game/story_logic.dart';
import 'package:ouroboros/models/item_catalog.dart';
import 'package:ouroboros/models/story_models.dart';
import 'package:ouroboros/states/inventory_state.dart';
import 'package:ouroboros/states/navigation_state.dart';
import 'package:ouroboros/states/player_state.dart';
import 'package:ouroboros/states/town_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Condition language', () {
    final memory = {'ran_at_once': 1, 'leads': 3, 'rep.fisherfolk': -1, 'bond.tam': 2};
    bool t(String c) => evaluateCondition(c, (n) => memory[n] ?? 0);

    test('names, numbers and comparisons', () {
      expect(t('ran_at_once'), isTrue);
      expect(t('stole_skiff'), isFalse, reason: 'unset reads as 0');
      expect(t('leads >= 3'), isTrue);
      expect(t('leads > 3'), isFalse);
      expect(t('rep.fisherfolk == -1'), isTrue);
      expect(t('rep.fisherfolk >= 1'), isFalse);
      expect(t('bond.tam != 0'), isTrue);
    });

    test('not, and, or, brackets', () {
      expect(t('!stole_skiff && ran_at_once'), isTrue);
      expect(t('stole_skiff || leads < 2'), isFalse);
      expect(t('!(stole_skiff || leads < 2)'), isTrue);
      expect(t('ran_at_once && (bond.tam >= 3 || leads >= 3)'), isTrue);
      expect(t(''), isTrue);
    });

    test('a broken condition is reported, not guessed', () {
      expect(() => validateCondition('leads >='), throwsFormatException);
      expect(() => validateCondition('(leads'), throwsFormatException);
      expect(() => validateCondition('leads @ 3'), throwsFormatException);
    });

    test('effects parse', () {
      expect(StoryEffect.parse('mercy +2').amount, 2);
      expect(StoryEffect.parse('sanity -5').amount, -5);
      expect(StoryEffect.parse('rep.fisherfolk =0').kind, StoryEffectKind.set);
      expect(StoryEffect.parse('flag ran_at_once').target, 'ran_at_once');
      expect(StoryEffect.parse('item rusted falchion').target, 'rusted falchion');
      expect(StoryEffect.parse('journal Two words, then more.').target, 'Two words, then more.');
      expect(() => StoryEffect.parse('mercy plus one'), throwsFormatException);
    });

    test('tracked values stay in range', () {
      expect(clampStoryValue('mercy', 14), 10);
      expect(clampStoryValue('rep.crown', -5), -2);
      expect(clampStoryValue('bond.tam', 9), 5);
      expect(clampStoryValue('leads', -1), 0);
    });
  });

  group('Act I file', () {
    final chapter = Chapter.fromJson(jsonDecode(File('assets/story/act1.json').readAsStringSync()) as Map<String, dynamic>);
    final encounters = jsonDecode(File('assets/data/encounters.json').readAsStringSync()) as Map<String, dynamic>;

    test('every link, condition, item and fight is real', () {
      expect(chapter.nodes, contains(chapter.startNodeId));
      for (final node in chapter.nodes.values) {
        for (final p in node.paragraphs) {
          if (p.showIf != null) validateCondition(p.showIf!);
        }
        for (final e in node.onEnter) {
          if (e.condition != null) validateCondition(e.condition!);
        }
        for (final c in node.choices) {
          final where = '${node.id}.${c.id}';
          for (final target in [c.nextNodeId, c.victoryNodeId, c.defeatNodeId, c.failNextNodeId]) {
            if (target != null) expect(chapter.nodes, contains(target), reason: '$where -> $target');
          }
          expect(c.nextNodeId != null || c.triggerEvent != null || c.nextChapterId != null, isTrue,
              reason: '$where goes nowhere');
          if (c.triggerEvent != null) expect(encounters, contains(c.triggerEvent), reason: where);
          for (final cond in c.conditions) {
            validateCondition(cond);
          }
          if (c.needs != null) expect(c.needsLabel, isNotNull, reason: '$where: a locked choice says what it needs');
          for (final e in [...c.effects, ...c.failEffects].expand((x) => x.effects)) {
            if (e.kind == StoryEffectKind.item) expect(ItemCatalog.byName, contains(e.target), reason: where);
          }
        }
      }
    });

    test('every scene can be reached from the start', () {
      final reached = <String>{chapter.startNodeId};
      final queue = [chapter.startNodeId];
      while (queue.isNotEmpty) {
        for (final c in chapter.nodes[queue.removeLast()]!.choices) {
          for (final t in [c.nextNodeId, c.victoryNodeId, c.defeatNodeId, c.failNextNodeId]) {
            if (t != null && reached.add(t)) queue.add(t);
          }
        }
      }
      expect(reached, containsAll(chapter.nodes.keys));
    });
  });

  group('Playing Act I', () {
    late StoryEngine story;
    late PlayerState player;

    setUp(() async {
      Get.testMode = true;
      Get.put(InventoryState());
      player = Get.put(PlayerState());
      Get.put(NavigationState());
      Get.put(TownState());
      player.initializeCustomCharacter('wren', 2);
      story = Get.put(StoryEngine());
      for (var i = 0; i < 200 && story.isLoading.value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    tearDown(Get.reset);

    Choice pick(String id) => story.visibleChoices(story.currentNode.value!).firstWhere((c) => c.id == id);
    void choose(String id) => story.makeChoice(pick(id));
    List<String> ids() => [for (final c in story.visibleChoices(story.currentNode.value!)) c.id];

    test('a new game opens Act I in the hills', () {
      expect(story.currentChapterId.value, 'act1');
      expect(story.currentNode.value!.id, 'a1_hills');
      expect(story.visibleParagraphs(story.currentNode.value!).first, contains('Mira'), reason: '{sister} filled in');
      // The assassin's Insight is 11, so "Watch the fires" (Insight 12) is hidden, not shown locked.
      expect(ids(), ['run', 'free', 'pelt']);
    });

    test('choices set flags and values, scenes apply their entry effects once', () {
      final sanity = player.vitals.value.currentSanity;
      final purse = Get.find<TownState>().purse;
      choose('pelt');
      expect(story.flags, contains('took_pelt'));
      expect(Get.find<TownState>().purse, purse + 20);
      expect(story.currentNode.value!.id, 'a1_return');
      expect(player.vitals.value.currentSanity, sanity - 5, reason: 'the hub costs sanity on arrival');
      expect(story.lastResult.value, contains('Twenty crowns'));

      choose('house');
      expect(ids(), ['frame', 'chest', 'hearth'], reason: 'three ways in; no way out until one is looked at');
      choose('frame');
      expect(story.value('leads'), 1);
      expect(story.journal.last, contains('list'));
      choose('leave_shawl');
      expect(ids(), ['chest', 'hearth', 'out'], reason: 'the doorframe is done');
      choose('out');
      expect(player.vitals.value.currentSanity, sanity - 5, reason: 'no second charge on return');
      expect(ids(), isNot(contains('house')), reason: 'visited sub-scene leaves the hub');
    });

    test('the square is a back-and-forth, not a menu', () {
      choose('run');
      choose('square');
      expect(ids(), ['help', 'ask', 'tam'], reason: 'three ways to start');
      choose('tam');
      expect(story.visibleParagraphs(story.currentNode.value!).first, contains('Wren.'), reason: '{name} in normal capitals');
      expect(ids(), ['promise', 'vengeance', 'stay']);
      choose('promise');
      expect(story.visibleParagraphs(story.currentNode.value!).join(), contains('All seven'));
      expect(story.value('bond.tam'), 2, reason: 'sitting with Tam +1, the promise +1');
      choose('well');
      expect(ids(), ['help', 'ask', 'steal', 'back']);
      choose('ask');
      choose('well');
      expect(ids(), ['steal', 'back'], reason: 'asking Brena directly closes helping her');

      // The assassin hero has 18 dexterity: the theft goes unseen.
      choose('steal');
      expect(story.flags, containsAll(['stole_from_store', 'has_food']));
      expect(story.value('rep.fisherfolk'), 0);
    });

    test('the cove is a conversation, then a decision, and the dusk follows it', () {
      choose('run');
      choose('cove');
      expect(ids(), ['name', 'sister', 'threat']);
      choose('name');
      expect(ids(), ['sister', 'threat', 'where'], reason: 'what is left to say, or the question that matters');
      choose('sister');
      expect(ids(), ['threat', 'where']);
      choose('where');
      expect(ids(), ['bind', 'swear', 'kill']);
      choose('bind');
      expect(ids(), ['leave'], reason: 'the assassin (Strength 10) cannot drag him; the choice is hidden');
      choose('leave');
      expect(story.flags, containsAll(['spared_rower', 'knows_rowers_name']));
      expect(story.value('leads'), 4, reason: 'red sail +1 (ran at once), sister +1, where +2');
      choose('night_cove');
      expect(story.currentNode.value!.id, 'a1_dusk');
      expect(story.visibleParagraphs(story.currentNode.value!).join(), contains('Corrin is sitting up'));
      choose('let_go');
      expect(story.currentNode.value!.id, 'a1_pyre');
      choose('vow');
      expect(story.value('rep.fisherfolk'), 1);
      expect(story.currentNode.value!.id, 'a1_counsel');
      expect(ids(), contains('all'), reason: '5 leads by now');
      expect(ids(), contains('skiff'), reason: 'Fisherfolk: Known from the vow');
      choose('post');
      expect(ids(), isNot(contains('post')));
      choose('skiff');
      expect(story.currentNode.value!.id, 'a1_leaving');
      expect(ids(), contains('blessing'));
      expect(ids(), isNot(contains('steal_skiff')), reason: 'no need to steal with a blessing');
      choose('blessing');
      choose('self');
      expect(story.currentNode.value!.id, 'a1_end');
      expect(story.value('mercy'), 5, reason: 'name +1, bind +2, let go +1, self +1');
    });

    test('a choice you cannot take is hidden until you can', () {
      choose('run');
      choose('cove');
      choose('threat');
      choose('where');
      choose('kill');
      choose('night_cove');
      expect(ids(), isNot(contains('village')), reason: "needs Tam's trust");
      story.values['bond.tam'] = 1;
      expect(ids(), contains('village'));
    });

    test('memory round-trips through restore', () async {
      choose('free');
      final flags = story.flags.toSet(), values = Map.of(story.values);
      story.flags.clear();
      story.values.clear();
      await story.restore(chapterId: 'act1', nodeId: 'a1_return', visited: ['a1_hills', 'a1_return'], flags: flags, values: values);
      expect(story.flags, contains('freed_vixen'));
      expect(story.value('mercy'), 1);
      expect(story.currentNode.value!.id, 'a1_return');
    });
  });
}
