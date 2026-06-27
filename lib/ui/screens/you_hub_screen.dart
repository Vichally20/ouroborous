import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/game_controller.dart';
import 'inventory_screen.dart';
import 'persona_screen.dart';
import 'stats_screen.dart';
import 'talents_screen.dart';

class YouHubScreen extends StatefulWidget {
  const YouHubScreen({super.key});

  @override
  State<YouHubScreen> createState() => _YouHubScreenState();
}

class _YouHubScreenState extends State<YouHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final gameController = Get.find<GameController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: gameController.activeYouTab.value.index,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index != gameController.activeYouTab.value.index) {
      gameController.selectYouTab(YouHubTab.values[_tabController.index]);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: VitruvianColors.voidBlack,
          child: TabBar(
            controller: _tabController,
            indicatorColor: VitruvianColors.agedBone,
            indicatorWeight: 3.0,
            labelColor: VitruvianColors.agedBone,
            unselectedLabelColor: VitruvianColors.sepiaUmber.withValues(alpha: 0.5),
            labelStyle: VitruvianTypography.serifTitle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: VitruvianTypography.serifTitle(fontSize: 11),
            tabs: const [
              Tab(text: 'EQUIPPED'),
              Tab(text: 'STATS'),
              Tab(text: 'INVENTORY'),
              Tab(text: 'TALENTS'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              PersonaScreen(),
              StatsScreen(),
              InventoryScreen(),
              TalentsScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
