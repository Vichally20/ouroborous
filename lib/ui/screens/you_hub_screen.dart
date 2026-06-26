import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/inventory_state.dart';
import '../../states/player_state.dart';
import 'inventory_screen.dart';
import 'persona_screen.dart';
import 'stats_screen.dart';
import 'talents_screen.dart';

class YouHubScreen extends StatelessWidget {
  final PlayerState playerState;
  final InventoryState inventoryState;

  const YouHubScreen({
    super.key,
    required this.playerState,
    required this.inventoryState,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: VitruvianColors.voidBlack,
            child: TabBar(
              indicatorColor: VitruvianColors.sepiaUmber,
              indicatorWeight: 2.0,
              labelColor: VitruvianColors.agedBone,
              unselectedLabelColor: Colors.white30,
              labelStyle: VitruvianTypography.monospaceData(fontSize: 10),
              tabs: const [
                Tab(text: 'PERSONA [4.1]'),
                Tab(text: 'STATS [4.2]'),
                Tab(text: 'INVENTORY [4.3]'),
                Tab(text: 'TALENTS [4.4]'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                PersonaScreen(playerState: playerState),
                StatsScreen(playerState: playerState),
                InventoryScreen(inventoryState: inventoryState, playerState: playerState),
                const TalentsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
