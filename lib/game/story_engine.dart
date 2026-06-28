import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/item.dart';
import '../../models/story_models.dart';
import '../../states/combat_state.dart';
import '../../states/inventory_state.dart';
import '../../states/player_state.dart';
import '../../states/navigation_state.dart';

/// A standalone story engine that reads chapter JSON files from assets/story/
/// and drives the narrative UI. Each chapter is a separate file loaded on demand.
class StoryEngine extends GetxController {
  // Reactive state
  final RxBool isLoading = true.obs;
  final Rx<Chapter?> currentChapter = Rx<Chapter?>(null);
  final Rx<StoryNode?> currentNode = Rx<StoryNode?>(null);

  // History tracking: which nodes the player has visited (persists across chapters)
  final RxList<String> visitedNodeIds = <String>[].obs;
  final RxList<String> completedChapterIds = <String>[].obs;
  final RxList<String> claimedLootNodeIds = <String>[].obs;
  final RxString currentChapterId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadChapter('chapter_1');
  }

  /// Dynamically load a single chapter JSON file from assets.
  Future<void> loadChapter(String chapterId) async {
    try {
      isLoading.value = true;

      final String jsonString =
          await rootBundle.loadString('assets/story/$chapterId.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final chapter = Chapter.fromJson(jsonMap);
      currentChapter.value = chapter;
      currentChapterId.value = chapterId;

      // Navigate to the chapter's starting node
      if (chapter.nodes.containsKey(chapter.startNodeId)) {
        currentNode.value = chapter.nodes[chapter.startNodeId];
        _markVisited(chapter.startNodeId);
      }
    } catch (e) {
      // Fallback: if no JSON found, stay on current node
      currentNode.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Core logic for when the player taps a choice button.
  void makeChoice(Choice choice) {
    // 1. Check attribute gates
    if (choice.requiredAttribute != null) {
      final playerState = Get.find<PlayerState>();
      final canPass = playerState.attributes.value.checkAttribute(
        choice.requiredAttribute!,
        choice.attributeRequirement!,
      );
      if (!canPass) {
        return; // UI handles showing "insufficient" feedback
      }
    }

    // NEW: Map Unlock Triggers
    if (choice.unlockLocationId != null) {
      Get.find<NavigationState>().unlockLocation(choice.unlockLocationId!);
    }
    if (choice.unlockCityId != null) {
      Get.find<NavigationState>().unlockCity(choice.unlockCityId!);
    }

    // 2. Special event triggers (combat, cutscenes, rewards)
    if (choice.triggerEvent != null) {
      _handleSpecialEvent(choice.triggerEvent!, choice.victoryNodeId);
      return;
    }

    // 3. Chapter transitions (load a whole new JSON file)
    if (choice.nextChapterId != null) {
      // Mark current chapter as completed
      if (currentChapterId.value.isNotEmpty) {
        completedChapterIds.add(currentChapterId.value);
      }
      loadChapter(choice.nextChapterId!);
      return;
    }

    // 4. Node transitions within the same chapter
    if (choice.nextNodeId != null && currentChapter.value != null) {
      final chapter = currentChapter.value!;
      if (chapter.nodes.containsKey(choice.nextNodeId)) {
        currentNode.value = chapter.nodes[choice.nextNodeId];
        _markVisited(choice.nextNodeId!);
      }
    }
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

  void _markVisited(String nodeId) {
    if (!visitedNodeIds.contains(nodeId)) {
      visitedNodeIds.add(nodeId);
    }
  }

  void _handleSpecialEvent(String eventId, String? victoryNodeId) {
    if (eventId.startsWith('combat_')) {
      Get.find<CombatController>().startCombat(eventId, victoryNodeId);
    } else {
      // Handle other special events (cutscenes, etc.)
    }
  }

  /// Manually transition to a specific node (used post-combat)
  void goToNode(String nodeId) {
    if (currentChapter.value != null && currentChapter.value!.nodes.containsKey(nodeId)) {
      currentNode.value = currentChapter.value!.nodes[nodeId];
      _markVisited(nodeId);
    }
  }

  void claimLoot(String nodeId, String lootCallout) {
    if (claimedLootNodeIds.contains(nodeId)) return;
    claimedLootNodeIds.add(nodeId);

    // Clean item name from callout prefixes
    String itemName = lootCallout
        .replaceAll('Loot Uncovered:', '')
        .replaceAll('Acquired:', '')
        .trim();

    final newItem = ArtifactItem(
      id: 'loot_${nodeId}_${DateTime.now().millisecondsSinceEpoch}',
      name: itemName,
      description: 'Acquired during the chronicle exploration.',
      category: ItemCategory.miscellaneous,
      rarity: ItemRarity.relic,
      weight: 1.0,
    );

    Get.find<InventoryState>().addItem(newItem);
  }

  /// Reset the story engine for a new game / playthrough.
  void resetStory() {
    visitedNodeIds.clear();
    completedChapterIds.clear();
    claimedLootNodeIds.clear();
    currentChapter.value = null;
    currentNode.value = null;
    currentChapterId.value = '';
    loadChapter('chapter_1');
  }
}
