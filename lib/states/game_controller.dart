import 'package:get/get.dart';
import 'combat_state.dart';
import 'inventory_state.dart';
import 'navigation_state.dart';
import 'player_state.dart';
import 'settings_state.dart';

enum MainHubTab { you, game, settings }
enum YouHubTab { equipped, stats, inventory, talents }

class GameController extends GetxController {
  final activeHubTab = MainHubTab.game.obs;
  final activeYouTab = YouHubTab.stats.obs;

  late final PlayerState playerState;
  late final InventoryState inventoryState;
  late final NavigationState navigationState;
  late final SettingsState settingsState;
  late final CombatController combatController;

  @override
  void onInit() {
    super.onInit();
    playerState = Get.put(PlayerState());
    inventoryState = Get.put(InventoryState());
    navigationState = Get.put(NavigationState());
    settingsState = Get.put(SettingsState());
    combatController = Get.put(CombatController());
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
