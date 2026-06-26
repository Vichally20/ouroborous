import 'package:flutter/material.dart';
import 'core/constants/colors.dart';
import 'core/constants/typography.dart';
import 'core/theme/manuscript_theme.dart';
import 'states/game_controller.dart';
import 'ui/screens/game_hub_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/you_hub_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VitruvianShadowApp());
}

class VitruvianShadowApp extends StatelessWidget {
  const VitruvianShadowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitruvian Shadow RPG',
      debugShowCheckedModeBanner: false,
      theme: ManuscriptTheme.darkTheme,
      home: const ManuscriptMainScaffold(),
    );
  }
}

class ManuscriptMainScaffold extends StatefulWidget {
  const ManuscriptMainScaffold({super.key});

  @override
  State<ManuscriptMainScaffold> createState() => _ManuscriptMainScaffoldState();
}

class _ManuscriptMainScaffoldState extends State<ManuscriptMainScaffold> {
  late final GameController _gameController;

  @override
  void initState() {
    super.initState();
    _gameController = GameController();
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _gameController,
      builder: (context, child) {
        final activeTab = _gameController.activeHubTab;

        Widget currentScreen;

        switch (activeTab) {
          case MainHubTab.you:
            currentScreen = YouHubScreen(
              playerState: _gameController.playerState,
              inventoryState: _gameController.inventoryState,
            );
            break;
          case MainHubTab.game:
            currentScreen = GameHubScreen(
              navigationState: _gameController.navigationState,
              playerState: _gameController.playerState,
            );
            break;
          case MainHubTab.settings:
            currentScreen = SettingsScreen(settingsState: _gameController.settingsState);
            break;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C0A08),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_book, color: VitruvianColors.sepiaUmber),
              onPressed: () => _gameController.selectHubTab(MainHubTab.game),
              tooltip: 'Open Game Chronicle',
            ),
            title: Text(
              'VITRUVIAN SHADOW',
              style: VitruvianTypography.serifTitle(
                fontSize: 20,
                color: const Color(0xFFE0C8B0),
              ).copyWith(letterSpacing: 2.0),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_stories, color: VitruvianColors.sepiaUmber),
                onPressed: () => _gameController.selectHubTab(MainHubTab.you),
                tooltip: 'Open Player Manuscript',
              ),
            ],
          ),
          body: currentScreen,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0C0A08),
              border: Border(top: BorderSide(color: Color(0xFF2A2218), width: 1.0)),
            ),
            child: BottomNavigationBar(
              currentIndex: activeTab.index,
              onTap: (index) => _gameController.selectHubTab(MainHubTab.values[index]),
              backgroundColor: const Color(0xFF0C0A08),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: VitruvianColors.agedBone,
              unselectedItemColor: VitruvianColors.sepiaUmber.withValues(alpha: 0.4),
              selectedLabelStyle: VitruvianTypography.serifTitle(fontSize: 11),
              unselectedLabelStyle: VitruvianTypography.serifTitle(fontSize: 10),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.portrait_outlined, size: 22),
                  ),
                  label: 'YOU',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.menu_book_outlined, size: 22),
                  ),
                  label: 'GAME',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.settings_outlined, size: 22),
                  ),
                  label: 'SETTINGS',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
