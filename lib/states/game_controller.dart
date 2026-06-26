import 'package:flutter/foundation.dart';
import 'inventory_state.dart';
import 'navigation_state.dart';
import 'player_state.dart';
import 'settings_state.dart';

enum MainHubTab { you, game, settings }

class GameController extends ChangeNotifier {
  MainHubTab _activeHubTab = MainHubTab.settings; // Default to settings as shown in mockup

  final PlayerState playerState = PlayerState();
  final InventoryState inventoryState = InventoryState();
  final NavigationState navigationState = NavigationState();
  final SettingsState settingsState = SettingsState();

  MainHubTab get activeHubTab => _activeHubTab;

  void selectHubTab(MainHubTab tab) {
    if (_activeHubTab != tab) {
      _activeHubTab = tab;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    playerState.dispose();
    inventoryState.dispose();
    navigationState.dispose();
    settingsState.dispose();
    super.dispose();
  }
}
