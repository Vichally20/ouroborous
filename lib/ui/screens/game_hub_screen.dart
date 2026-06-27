import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../states/combat_state.dart';
import '../../states/navigation_state.dart';
import 'chronicle_screen.dart';
import 'navigation_screen.dart';
import 'combat_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navState = Get.find<NavigationState>();
    final combatController = Get.find<CombatController>();

    return Obx(() {
      if (combatController.inCombat.value) {
        return const CombatScreen();
      } else if (navState.isShowingMap.value) {
        return const NavigationScreen();
      } else {
        return const ChronicleScreen();
      }
    });
  }
}
