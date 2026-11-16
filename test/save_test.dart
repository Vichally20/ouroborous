import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/game/story_engine.dart';
import 'package:ouroboros/models/character_class.dart';
import 'package:ouroboros/models/hero_portraits.dart';
import 'package:ouroboros/states/combat_state.dart';
import 'package:ouroboros/states/game_controller.dart';
import 'package:ouroboros/states/inventory_state.dart';
import 'package:ouroboros/states/navigation_state.dart';
import 'package:ouroboros/states/player_state.dart';
import 'package:ouroboros/states/save_state.dart';
import 'package:ouroboros/states/town_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SaveState save;

  Future<void> settle() async {
    for (var i = 0; i < 200; i++) {
      final storyReady = Get.isRegistered<StoryEngine>() && !Get.find<StoryEngine>().isLoading.value;
      if (save.ready.value && storyReady) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.put(GameController());
    save = Get.put(SaveState());
    await settle();
  });
  tearDown(Get.reset);

  Future<void> beginAssassin() async {
    save.startNewGame(0);
    await settle();
    final player = Get.find<PlayerState>();
    final index = player.heroes.indexWhere((h) => h.characterClass.type == PersonalityClassType.assassin);
    await save.beginChronicle(
      name: 'Wren',
      heroIndex: index,
      portrait: HeroPortraits.of(PersonalityClassType.assassin)[1],
    );
  }

  test('a fresh install starts on the menu with three empty slots', () {
    expect(save.screen.value, AppScreen.menu);
    expect(save.slots, [null, null, null]);
    expect(save.latestSlot, isNull);
    expect(save.firstEmptySlot, 0);
  });

  test('beginning a chronicle enters the game and writes slot 1', () async {
    await beginAssassin();
    expect(save.screen.value, AppScreen.game);
    final s = save.slots[0]!;
    expect(s.heroName, 'WREN');
    expect(s.classType, PersonalityClassType.assassin);
    expect(s.portrait, HeroPortraits.of(PersonalityClassType.assassin)[1]);
    expect(save.latestSlot, 0);
    expect(Get.find<PlayerState>().activeHero.portrait, s.portrait);
  });

  test('a save loads back exactly: hero, gear, purse, vault, map and story', () async {
    await beginAssassin();
    final player = Get.find<PlayerState>();
    final town = Get.find<TownState>();
    final nav = Get.find<NavigationState>();
    final inv = Get.find<InventoryState>();

    final bow = player.activeHero.loadout.mainHand!;
    expect(town.temper(bow, equipped: true), isNull);
    expect(town.deposit(500), isNull);
    player.activeHero.vitals.currentHp = 42;
    player.level.value = 3;
    player.activeHero.unlockedTalents.add('extra_talent');
    nav.unlockLocation('market');
    nav.enterCity('aethel_cap');
    nav.moveToLocation('inn');
    final purse = town.purse;
    final ledgerSize = inv.ledger.length;
    final node = Get.find<StoryEngine>().currentNode.value!.id;

    expect(await save.saveNow(), isTrue);

    // Wander off into a different new game, then load the first one.
    save.startNewGame(1);
    await settle();
    expect(Get.find<PlayerState>().hasCreatedCharacter.value, isFalse);

    expect(await save.load(0), isNull);
    await settle();
    final p = Get.find<PlayerState>();
    expect(identical(p, player), isFalse, reason: 'a fresh session was built');
    expect(save.screen.value, AppScreen.game);
    expect(save.activeSlot.value, 0);
    expect(p.activeHero.name, 'WREN');
    expect(p.activeHero.characterClass.type, PersonalityClassType.assassin);
    expect(p.activeHero.portrait, HeroPortraits.of(PersonalityClassType.assassin)[1]);
    expect(p.activeHero.vitals.currentHp, 42);
    expect(p.vitals.value.currentHp, 42, reason: 'HUD vitals bound to the active hero');
    expect(p.level.value, 3);
    expect(p.activeHero.unlockedTalents, contains('extra_talent'));
    expect(p.activeHero.loadout.mainHand!.displayName, '${bow.name} +1');
    expect(p.activeHero.loadout.mainHand!.weaponRange, bow.weaponRange);
    expect(Get.find<TownState>().purse, purse);
    expect(Get.find<TownState>().bankedCrowns.value, 500);
    expect(Get.find<InventoryState>().ledger.length, ledgerSize);
    expect(Get.find<NavigationState>().unlockedLocationIds, contains('market'));
    expect(Get.find<NavigationState>().presentLocationId.value, 'inn');
    expect(Get.find<StoryEngine>().currentNode.value!.id, node);
    expect(save.slots[0]!.place, 'The Hills Above Saltmere', reason: 'the story scene names the save');
  });

  test('retreating after a defeat restores the last checkpoint, before the fight', () async {
    await beginAssassin();
    final story = Get.find<StoryEngine>();
    final nodeBefore = story.currentNode.value!.id;
    final hpBefore = Get.find<PlayerState>().activeHero.vitals.currentHp;
    expect(await save.saveNow(), isTrue);

    // Take a fight and lose it: the defeat leaves the hero on 1 HP, mid-battle.
    Get.find<CombatController>().inCombat.value = true;
    Get.find<PlayerState>().activeHero.vitals.currentHp = 1;
    await Future<void>.delayed(SaveState.autosaveDelay + const Duration(milliseconds: 200));

    expect(await save.restoreCheckpoint(), isNull);
    await settle();
    expect(Get.find<CombatController>().inCombat.value, isFalse);
    expect(Get.find<PlayerState>().activeHero.vitals.currentHp, hpBefore, reason: 'the defeat was never saved');
    expect(Get.find<StoryEngine>().currentNode.value!.id, nodeBefore);
    expect(save.screen.value, AppScreen.game);
  });

  test('no checkpoint without a slot', () async {
    expect(await save.restoreCheckpoint(), contains('no saved checkpoint'));
  });

  test('no saving mid-battle', () async {
    await beginAssassin();
    Get.find<CombatController>().inCombat.value = true;
    expect(await save.saveNow(), isFalse);
  });

  test('autosave follows play', () async {
    await beginAssassin();
    final before = save.slots[0]!.savedAt;
    Get.find<TownState>().deposit(100);
    await Future<void>.delayed(SaveState.autosaveDelay + const Duration(milliseconds: 200));
    expect(save.slots[0]!.savedAt.isAfter(before), isTrue);
  });

  test('delete and wipe empty the slots', () async {
    await beginAssassin();
    await save.returnToMenu();
    expect(save.screen.value, AppScreen.menu);
    await save.deleteSlot(0);
    expect(save.slots[0], isNull);

    await beginAssassin();
    await save.wipeAll();
    expect(save.hasAnySave, isFalse);
    expect(save.screen.value, AppScreen.menu);
  });
}
