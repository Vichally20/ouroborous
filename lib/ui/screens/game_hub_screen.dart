import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/navigation_state.dart';
import '../../states/player_state.dart';
import 'chronicle_screen.dart';
import 'navigation_screen.dart';

class GameHubScreen extends StatelessWidget {
  final NavigationState navigationState;
  final PlayerState playerState;

  const GameHubScreen({
    super.key,
    required this.navigationState,
    required this.playerState,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: VitruvianColors.voidBlack,
            child: TabBar(
              indicatorColor: VitruvianColors.sepiaUmber,
              indicatorWeight: 2.0,
              labelColor: VitruvianColors.agedBone,
              unselectedLabelColor: Colors.white30,
              labelStyle: VitruvianTypography.monospaceData(fontSize: 11),
              tabs: const [
                Tab(icon: Icon(Icons.map, size: 16), text: 'NAVIGATION MAP [4.5]'),
                Tab(icon: Icon(Icons.history_edu, size: 16), text: 'THE CHRONICLE [3.B]'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                NavigationScreen(navigationState: navigationState),
                ChronicleScreen(playerState: playerState),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
