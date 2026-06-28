import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/constants/colors.dart';
import 'core/constants/typography.dart';
import 'core/theme/manuscript_theme.dart';
import 'states/game_controller.dart';
import 'states/navigation_state.dart';
import 'ui/screens/game_hub_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/you_hub_screen.dart';
import 'ui/screens/intro_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VitruvianShadowApp());
}

class VitruvianShadowApp extends StatelessWidget {
  const VitruvianShadowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gameController = Get.put(GameController());

    return GetMaterialApp(
      title: 'Vitruvian Shadow RPG',
      debugShowCheckedModeBanner: false,
      theme: ManuscriptTheme.darkTheme,
      home: Obx(() {
        if (gameController.playerState.hasCreatedCharacter.value) {
          return const ManuscriptMainScaffold();
        } else {
          return const IntroScreen();
        }
      }),
    );
  }
}

class ManuscriptMainScaffold extends StatelessWidget {
  const ManuscriptMainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final gameController = Get.find<GameController>();
    final navState = Get.find<NavigationState>();

    return Obx(() {
      final activeTab = gameController.activeHubTab.value;
      final currentNode = navState.currentNode;

      Widget currentScreen;
      String appBarTitle = 'VITRUVIAN SHADOW';
      List<Widget> actions = [];
      Widget? leadingBtn;

      switch (activeTab) {
        case MainHubTab.you:
          currentScreen = const YouHubScreen();
          appBarTitle = 'VITRUVIAN SHADOW';
          actions = [
            IconButton(
              icon: const Icon(Icons.map_outlined, color: VitruvianColors.sepiaUmber),
              onPressed: () => gameController.selectHubTab(MainHubTab.game),
              tooltip: 'Open Game Chronicle',
            ),
          ];
          break;
        case MainHubTab.game:
          currentScreen = const GameHubScreen();
          appBarTitle = navState.isShowingMap.value ? currentNode.title : 'VITRUVIAN SHADOW';
          actions = [
            IconButton(
              icon: Icon(
                navState.isShowingMap.value ? Icons.history_edu : Icons.map_outlined,
                color: VitruvianColors.sepiaUmber,
              ),
              onPressed: navState.toggleChronicleMap,
              tooltip: navState.isShowingMap.value ? 'Open Chronicle' : 'Open Tactical Map',
            ),
          ];
          break;
        case MainHubTab.settings:
          currentScreen = const SettingsScreen();
          appBarTitle = 'VITRUVIAN SHADOW';
          break;
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C0A08),
          elevation: 0,
          leading: leadingBtn,
          title: Text(
            appBarTitle,
            style: VitruvianTypography.serifTitle(
              fontSize: activeTab == MainHubTab.game ? 20 : 18,
              color: VitruvianColors.agedBone,
            ).copyWith(letterSpacing: 1.2),
          ),
          centerTitle: true,
          actions: actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: const Color(0xFF2A2218), height: 1.0),
          ),
        ),
        body: currentScreen,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C0A08),
            border: Border(top: BorderSide(color: Color(0xFF2A2218), width: 1.0)),
          ),
          child: BottomNavigationBar(
            currentIndex: activeTab.index,
            onTap: (index) => gameController.selectHubTab(MainHubTab.values[index]),
            backgroundColor: const Color(0xFF0C0A08),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: VitruvianColors.agedBone,
            unselectedItemColor: VitruvianColors.sepiaUmber.withValues(alpha: 0.4),
            selectedLabelStyle: VitruvianTypography.serifTitle(fontSize: 12),
            unselectedLabelStyle: VitruvianTypography.serifTitle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.portrait_outlined, size: 22),
                ),
                label: 'You',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.menu_book_outlined, size: 22),
                ),
                label: 'Game',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.settings_outlined, size: 22),
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      );
    });
  }
}
