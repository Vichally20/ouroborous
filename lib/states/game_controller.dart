import 'package:get/get.dart';
import '../game/story_engine.dart';
import 'combat_state.dart';
import 'inventory_state.dart';
import 'navigation_state.dart';
import 'player_state.dart';
import 'settings_state.dart';
import 'town_state.dart';

enum MainHubTab { you, game, settings }
enum YouHubTab { equipped, stats, inventory, talents }

class GameController extends GetxController {
  final activeHubTab = MainHubTab.game.obs;
  final activeYouTab = YouHubTab.stats.obs;

  // Looked up each time: a new game or a loaded save replaces these controllers.
  PlayerState get playerState => Get.find<PlayerState>();
  InventoryState get inventoryState => Get.find<InventoryState>();
  NavigationState get navigationState => Get.find<NavigationState>();
  SettingsState get settingsState => Get.find<SettingsState>();
  CombatController get combatController => Get.find<CombatController>();
  StoryEngine get storyEngine => Get.find<StoryEngine>();

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<SettingsState>()) Get.put(SettingsState());
    _putSession();
  }

  /// Everything that belongs to one playthrough. Settings outlive it.
  void _putSession() {
    Get.put(PlayerState());
    Get.put(InventoryState());
    Get.put(NavigationState());
    Get.put(TownState());
    Get.put(StoryEngine());
    Get.put(CombatController());
  }

  /// Throws away the current playthrough and starts a blank one (new game, or
  /// the clean slate a save is loaded onto).
  void resetSession() {
    Get.delete<CombatController>(force: true);
    Get.delete<StoryEngine>(force: true);
    Get.delete<TownState>(force: true);
    Get.delete<NavigationState>(force: true);
    Get.delete<InventoryState>(force: true);
    Get.delete<PlayerState>(force: true);
    _putSession();
    activeHubTab.value = MainHubTab.game;
    activeYouTab.value = YouHubTab.stats;
  }

  void selectHubTab(MainHubTab tab) {
    activeHubTab.value = tab;
  }

  void selectYouTab(YouHubTab tab) {
    activeYouTab.value = tab;
  }

  String get currentYouTitle {
    switch (activeYouTab.value) {
      case YouHubTab.equipped:
        return 'Equipped';
      case YouHubTab.stats:
        return 'Stats';
      case YouHubTab.inventory:
        return 'Inventory';
      case YouHubTab.talents:
        return 'Talents';
    }
  }
}
