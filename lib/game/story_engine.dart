import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/item_catalog.dart';
import '../../models/story_models.dart';
import '../../states/combat_state.dart';
import '../../states/inventory_state.dart';
import '../../states/player_state.dart';
import '../../states/navigation_state.dart';
import '../../states/town_state.dart';
import 'story_logic.dart';

/// A standalone story engine that reads chapter JSON files from assets/story/
/// and drives the narrative UI. Each chapter is a separate file loaded on demand.
///
/// It also keeps the story's memory: flags, tracked values (mercy, leads,
/// reputation, bonds), a journal, and which choices were already used.
class StoryEngine extends GetxController {
  /// The chapter a new game starts in.
  static const firstChapterId = 'act1';

  /// Working name of the hero's sister; `{sister}` in story text.
  static const sisterName = 'Mira';

  // Reactive state
  final RxBool isLoading = true.obs;
  final Rx<Chapter?> currentChapter = Rx<Chapter?>(null);
  final Rx<StoryNode?> currentNode = Rx<StoryNode?>(null);

  // History tracking: which nodes the player has visited (persists across chapters)
  final RxList<String> visitedNodeIds = <String>[].obs;
  final RxList<String> completedChapterIds = <String>[].obs;
  final RxList<String> claimedLootNodeIds = <String>[].obs;
  final RxString currentChapterId = ''.obs;

  // ─── Story memory ───
  final RxSet<String> flags = <String>{}.obs;
  final RxMap<String, int> values = <String, int>{}.obs;
  final RxList<String> journal = <String>[].obs;

  /// What the last choice did, shown at the top of the scene it led to.
  final RxnString lastResult = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadChapter(firstChapterId);
  }

  /// Bumped by every load, so a slow earlier load (the first chapter kicked off in
  /// onInit) can't overwrite a save that was restored after it.
  int _loadToken = 0;

  /// Dynamically load a single chapter JSON file from assets, at its start node
  /// or at [atNodeId] when restoring a save.
  Future<void> loadChapter(String chapterId, {String? atNodeId}) async {
    final token = ++_loadToken;
    try {
      isLoading.value = true;

      final String jsonString =
          await rootBundle.loadString('assets/story/$chapterId.json');
      if (token != _loadToken) return;
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final chapter = Chapter.fromJson(jsonMap);
      currentChapter.value = chapter;
      currentChapterId.value = chapterId;

      // Navigate to the chapter's starting node (or the saved one)
      final nodeId = atNodeId != null && chapter.nodes.containsKey(atNodeId) ? atNodeId : chapter.startNodeId;
      if (chapter.nodes.containsKey(nodeId)) _enter(chapter.nodes[nodeId]!);
    } catch (e) {
      // Fallback: if no JSON found, stay on current node
      if (token == _loadToken) currentNode.value = null;
    } finally {
      if (token == _loadToken) isLoading.value = false;
    }
  }

  /// Puts the story back where a save file left it.
  Future<void> restore({
    required String chapterId,
    String? nodeId,
    Iterable<String> visited = const [],
    Iterable<String> completed = const [],
    Iterable<String> claimed = const [],
    Iterable<String> flags = const [],
    Map<String, int> values = const {},
    Iterable<String> journal = const [],
  }) async {
    visitedNodeIds.assignAll(visited);
    completedChapterIds.assignAll(completed);
    claimedLootNodeIds.assignAll(claimed);
    this.flags
      ..clear()
      ..addAll(flags);
    this.values.assignAll(values);
    this.journal.assignAll(journal);
    lastResult.value = null;
    await loadChapter(chapterId.isEmpty ? firstChapterId : chapterId, atNodeId: nodeId);
  }

  // ─── Reading the story's memory ───

  /// The number a condition sees for [name]: a flag (1 or 0), a tracked value, or
  /// a live game number (`sanity`, `crowns`, `attr.insight`, `seen.<scene id>`).
  int lookup(String name) {
    if (flags.contains(name)) return 1;
    if (name == 'sanity') return Get.isRegistered<PlayerState>() ? Get.find<PlayerState>().vitals.value.currentSanity : 0;
    if (name == 'crowns') return Get.isRegistered<TownState>() ? Get.find<TownState>().purse : 0;
    if (name.startsWith('attr.')) {
      if (!Get.isRegistered<PlayerState>()) return 0;
      return Get.find<PlayerState>().attributes.value.getAttributeValue(name.substring(5));
    }
    if (name.startsWith('seen.')) return visitedNodeIds.contains(name.substring(5)) ? 1 : 0;
    return values[name] ?? 0;
  }

  bool test(String? condition) => evaluateCondition(condition, lookup);

  int value(String name) => values[name] ?? 0;

  /// [text] with `{name}` (the hero's name) and `{sister}` filled in.
  String render(String text) {
    if (!text.contains('{')) return text;
    return text.replaceAll('{name}', heroName).replaceAll('{sister}', sisterName);
  }

  /// The active hero's name in normal capitals ("SERAPHINE" → "Seraphine").
  String get heroName {
    if (!Get.isRegistered<PlayerState>()) return 'Aleph';
    final raw = Get.find<PlayerState>().activeHero.name.trim();
    return raw
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// The paragraphs of [node] whose conditions hold, with tokens filled in.
  List<String> visibleParagraphs(StoryNode node) =>
      [for (final p in node.paragraphs) if (test(p.showIf)) render(p.text)];

  static String _choiceKey(StoryNode node, Choice c) => 'chosen:${node.id}.${c.id}';
  static String _groupKey(StoryNode node, String group) => 'group:${node.id}.$group';

  /// The choices the player can see in [node]: their conditions hold, the player
  /// can take them (a choice you can't take is hidden, not shown locked), a one-time
  /// choice hasn't been used, and nothing else in their group has been picked.
  List<Choice> visibleChoices(StoryNode node) => [
        for (final c in node.choices)
          if (test(c.showIf) &&
              !isLocked(c) &&
              !(c.once && flags.contains(_choiceKey(node, c))) &&
              !(c.group != null && flags.contains(_groupKey(node, c.group!))))
            c,
      ];

  /// A visible choice the player can't take yet (its `needs`, or an old-style attribute gate).
  bool isLocked(Choice choice) => !test(choice.needs) || !canPassGate(choice);

  // ─── Making choices ───

  /// Core logic for when the player taps a choice button.
  void makeChoice(Choice choice) {
    final node = currentNode.value;
    if (isLocked(choice)) return; // UI explains why

    if (node != null) {
      if (choice.once) flags.add(_choiceKey(node, choice));
      if (choice.group != null) flags.add(_groupKey(node, choice.group!));
    }

    // Tests and effects
    final passed = choice.check == null || test(choice.check);
    _applyAll(passed ? choice.effects : choice.failEffects);
    final result = passed ? choice.result : (choice.failResult ?? choice.result);
    lastResult.value = result == null ? null : render(result);

    // Map unlocks
    if (choice.unlockLocationId != null) {
      Get.find<NavigationState>().unlockLocation(choice.unlockLocationId!);
    }
    if (choice.unlockCityId != null) {
      Get.find<NavigationState>().unlockCity(choice.unlockCityId!);
    }

    // Special event triggers (combat, cutscenes, rewards)
    if (choice.triggerEvent != null) {
      _handleSpecialEvent(choice.triggerEvent!, choice.victoryNodeId, choice.defeatNodeId);
      return;
    }

    // Chapter transitions (load a whole new JSON file)
    if (choice.nextChapterId != null) {
      if (currentChapterId.value.isNotEmpty) {
        completedChapterIds.add(currentChapterId.value);
      }
      loadChapter(choice.nextChapterId!);
      return;
    }

    // Node transitions within the same chapter
    final next = !passed && choice.failNextNodeId != null ? choice.failNextNodeId : choice.nextNodeId;
    if (next != null) goToNode(next);
  }

  void _applyAll(List<StoryEffectEntry> entries) {
    for (final entry in entries) {
      if (!test(entry.condition)) continue;
      for (final e in entry.effects) {
        _apply(e);
      }
    }
  }

  void _apply(StoryEffect e) {
    switch (e.kind) {
      case StoryEffectKind.flag:
        flags.add(e.target);
      case StoryEffectKind.unflag:
        flags.remove(e.target);
      case StoryEffectKind.journal:
        journal.add(render(e.target));
      case StoryEffectKind.item:
        final item = ItemCatalog.byName[e.target.toLowerCase()];
        if (item != null && Get.isRegistered<InventoryState>()) Get.find<InventoryState>().addItem(item);
      case StoryEffectKind.add:
      case StoryEffectKind.set:
        final current = lookup(e.target);
        final next = e.kind == StoryEffectKind.add ? current + e.amount : e.amount;
        _setValue(e.target, next, current);
    }
  }

  void _setValue(String name, int next, int current) {
    if (name == 'sanity') {
      if (!Get.isRegistered<PlayerState>()) return;
      final player = Get.find<PlayerState>();
      final v = player.vitals.value;
      v.currentSanity = next.clamp(0, v.maxSanity);
      player.vitals.refresh();
      player.heroes.refresh();
      return;
    }
    if (name == 'crowns') {
      if (!Get.isRegistered<TownState>()) return;
      Get.find<TownState>().addCrowns(next - current);
      return;
    }
    values[name] = clampStoryValue(name, next);
  }

  /// Check if an attribute gate passes for a given choice.
  bool canPassGate(Choice choice) {
    if (choice.requiredAttribute == null) return true;
    final playerState = Get.find<PlayerState>();
    return playerState.attributes.value.checkAttribute(
      choice.requiredAttribute!,
      choice.attributeRequirement!,
    );
  }

  /// Has this node been visited before in the current playthrough?
  bool hasVisited(String nodeId) => visitedNodeIds.contains(nodeId);

  /// Shows [node]; on the first visit its `onEnter` effects apply.
  void _enter(StoryNode node) {
    final first = !visitedNodeIds.contains(node.id);
    if (first) visitedNodeIds.add(node.id);
    currentNode.value = node;
    if (first) _applyAll(node.onEnter);
  }

  void _handleSpecialEvent(String eventId, String? victoryNodeId, String? defeatNodeId) {
    if (eventId.startsWith('combat_')) {
      Get.find<CombatController>().startCombat(eventId, victoryNodeId, defeatNodeId);
    } else {
      // Handle other special events (cutscenes, etc.)
    }
  }

  /// Manually transition to a specific node (used post-combat)
  void goToNode(String nodeId) {
    if (currentChapter.value != null && currentChapter.value!.nodes.containsKey(nodeId)) {
      _enter(currentChapter.value!.nodes[nodeId]!);
    }
  }

  void claimLoot(String nodeId, String lootCallout) {
    if (claimedLootNodeIds.contains(nodeId)) return;
    claimedLootNodeIds.add(nodeId);

    // Real items (equippable weapons, quest relics) from the catalogue; unknown loot
    // still arrives as a miscellaneous relic.
    final inventory = Get.find<InventoryState>();
    for (final item in ItemCatalog.fromLootCallout(lootCallout, fallbackIdPrefix: 'loot_$nodeId')) {
      inventory.addItem(item);
    }
  }

  /// Reset the story engine for a new game / playthrough.
  void resetStory() {
    visitedNodeIds.clear();
    completedChapterIds.clear();
    claimedLootNodeIds.clear();
    flags.clear();
    values.clear();
    journal.clear();
    lastResult.value = null;
    currentChapter.value = null;
    currentNode.value = null;
    currentChapterId.value = '';
    loadChapter(firstChapterId);
  }
}
