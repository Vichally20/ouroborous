import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/item.dart';
import '../../models/character_class.dart';
import '../../states/player_state.dart';
import '../../states/combat_state.dart';
import '../../states/inventory_state.dart';
import '../../models/combat_models.dart';
import '../widgets/etched_container.dart';

class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late Worker _hpWorker;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    final combatController = Get.find<CombatController>();
    
    // Trigger screen shake when player HP drops
    _hpWorker = ever(combatController.playerHp, (hp) {
      if (mounted && hp < combatController.playerMaxHp.value && hp > 0) {
        _shakeController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _hpWorker.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combatController = Get.find<CombatController>();

    return Obx(() {
      final isPlayerTurn = combatController.isPlayerTurn.value;
      final enemies = combatController.enemies;
      final playerHp = combatController.playerHp.value;
      final playerMaxHp = combatController.playerMaxHp.value;
      final playerStamina = combatController.playerStamina.value;
      final playerMaxStamina = combatController.playerMaxStamina.value;
      final playerAp = combatController.playerAp.value;
      final selectedEnemyId = combatController.selectedEnemyId.value;

      // Handle Victory / Defeat Overlays
      bool isVictory = enemies.every((e) => e.isDead.value);
      bool isDefeat = playerHp <= 0;

      return Scaffold(
        backgroundColor: VitruvianColors.voidBlack,
        body: Stack(
          children: [
            // Shaking main view
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final dx = _shakeAnimation.value * (1.0 - _shakeController.value) * (0.5 - (0.5 * (1.0 - _shakeController.value)));
                return Transform.translate(
                  offset: Offset(dx * 2, 0),
                  child: child,
                );
              },
              child: SafeArea(
                child: Column(
                  children: [
                    // Header: Turn Info
                    _buildHeader(combatController, isPlayerTurn),

                    // Body: Lane Visualizer (Right Panel occupying full space)
                    Expanded(
                      child: _buildBattlefield(combatController, enemies, selectedEnemyId),
                    ),

                    // Bottom Control HUD deck
                    _buildBottomHudDeck(
                      context,
                      combatController,
                      isPlayerTurn,
                      playerHp,
                      playerMaxHp,
                      playerStamina,
                      playerMaxStamina,
                      playerAp,
                    ),
                  ],
                ),
              ),
            ),

            // Defeat Overlay
            if (isDefeat) _buildDefeatOverlay(combatController),

            // Victory Overlay
            if (isVictory) _buildVictoryOverlay(combatController),
          ],
        ),
      );
    });
  }

  // Header Turn banner
  Widget _buildHeader(CombatController controller, bool isPlayerTurn) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isPlayerTurn ? const Color(0xFF1E160E) : const Color(0xFF2C0F0F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPlayerTurn ? const Color(0xFFC89B5D) : VitruvianColors.rustBlood,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isPlayerTurn ? 'YOUR TURN' : 'ENEMIES MOVING...',
                style: VitruvianTypography.serifTitle(
                  fontSize: 18,
                  color: isPlayerTurn ? const Color(0xFFE4DCD0) : const Color(0xFFFFAAAA),
                ).copyWith(letterSpacing: 1.5),
              ),
            ],
          ),
          if (isPlayerTurn)
            InkWell(
              onTap: controller.endPlayerTurn,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF151310),
                  border: Border.all(color: VitruvianColors.sepiaUmber),
                ),
                child: Text(
                  'END TURN',
                  style: VitruvianTypography.monospaceData(
                    fontSize: 11,
                    color: VitruvianColors.agedBone,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }



  // Right panel battlefield
  Widget _buildBattlefield(
    CombatController controller,
    List<Enemy> enemies,
    String? selectedEnemyId,
  ) {
    return Container(
      color: const Color(0xFF080605),
      child: Column(
        children: [
          // Lane 1: Enemy Back Line (Row 1)
          Expanded(
            child: _buildLaneRow(
              title: 'Enemy Back Line',
              laneEnemies: enemies.where((e) => e.lane.value == 'back').toList(),
              selectedId: selectedEnemyId,
              onTap: controller.selectEnemy,
              controller: controller,
            ),
          ),
          const Divider(color: Color(0xFF1E1710)),

          // Lane 2: Enemy Front Line (Row 2)
          Expanded(
            child: _buildLaneRow(
              title: 'Enemy Front Line',
              laneEnemies: enemies.where((e) => e.lane.value == 'front').toList(),
              selectedId: selectedEnemyId,
              onTap: controller.selectEnemy,
              controller: controller,
            ),
          ),
          
          // Tactical Divide
          Container(
            height: 16,
            color: const Color(0xFF120E0A),
            alignment: Alignment.center,
            child: Text(
              '⚔   LANE DIVISION   ⚔',
              style: VitruvianTypography.monospaceData(
                fontSize: 9,
                color: VitruvianColors.sepiaUmber.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Lane 3: Player Front Line (Row 3)
          Expanded(
            child: _buildPlayerLane(
              isFront: true,
              controller: controller,
            ),
          ),
          const Divider(color: Color(0xFF1E1710)),

          // Lane 4: Player Back Line (Row 4)
          Expanded(
            child: _buildPlayerLane(
              isFront: false,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }

  // Lane containing enemies
  Widget _buildLaneRow({
    required String title,
    required List<Enemy> laneEnemies,
    required String? selectedId,
    required Function(String) onTap,
    required CombatController controller,
  }) {
    return Stack(
      children: [
        // Watermarked lane name
        Positioned(
          left: 12,
          top: 8,
          child: Text(
            title.toUpperCase(),
            style: VitruvianTypography.monospaceData(
              fontSize: 9,
              color: const Color(0xFF28221B),
            ),
          ),
        ),
        
        // Enemy cards
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: laneEnemies.map((enemy) {
              final isSelected = selectedId == enemy.id;
              final isDead = enemy.isDead.value;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () => isDead ? null : onTap(enemy.id),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        height: 110,
                        decoration: BoxDecoration(
                          color: isDead ? Colors.black.withValues(alpha: 0.8) : const Color(0xFF100D0A),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFC89B5D)
                                : isDead
                                    ? Colors.transparent
                                    : const Color(0xFF2C2218),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFC89B5D).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            // Thumbnail Image or placeholder
                            Expanded(
                              child: Opacity(
                                opacity: isDead ? 0.3 : 1.0,
                                child: Image.asset(
                                  enemy.imageAsset,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            // HP Bar
                            if (!isDead)
                              Container(
                                color: const Color(0xFF1A1A1A),
                                child: Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value: enemy.hp.value / enemy.maxHp,
                                      backgroundColor: const Color(0xFF220A0A),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF8B0000),
                                      ),
                                      minHeight: 4,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Text(
                                        '${enemy.hp.value}/${enemy.maxHp}',
                                        style: VitruvianTypography.monospaceData(fontSize: 9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isDead)
                              Container(
                                color: const Color(0xFF111111),
                                width: double.infinity,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Icon(
                                  Icons.dangerous,
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Target indicator
                      if (isSelected && !isDead)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFC89B5D),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(
                              Icons.ads_click,
                              size: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),

                      // Floating Damage Popups
                      if (controller.damagePopups.containsKey(enemy.id))
                        Positioned(
                          top: -24,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              controller.damagePopups[enemy.id]!,
                              style: VitruvianTypography.monospaceData(
                                fontSize: 16,
                                color: const Color(0xFFFF5555),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Player lane representation
  Widget _buildPlayerLane({
    required bool isFront,
    required CombatController controller,
  }) {
    final playerLane = controller.playerLane.value;
    final isPlayerInThisLane = (isFront && playerLane == 'front') || (!isFront && playerLane == 'back');

    final playerState = Get.find<PlayerState>();
    final currentClass = playerState.characterClass.value;
    String classImageAsset;
    switch (currentClass.type) {
      case PersonalityClassType.warrior:
        classImageAsset = 'assets/images/class_warrior.jpg';
        break;
      case PersonalityClassType.sorcerer:
        classImageAsset = 'assets/images/class_sorcerer.jpg';
        break;
      case PersonalityClassType.assassin:
        classImageAsset = 'assets/images/class_assassin.jpg';
        break;
    }

    return Stack(
      children: [
        // Watermarked lane name
        Positioned(
          left: 12,
          top: 8,
          child: Text(
            (isFront ? 'Player Front Line' : 'Player Back Line').toUpperCase(),
            style: VitruvianTypography.monospaceData(
              fontSize: 9,
              color: const Color(0xFF28221B),
            ),
          ),
        ),

        // Player card
        if (isPlayerInThisLane)
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 100,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF100D0A),
                    border: Border.all(
                      color: VitruvianColors.sepiaUmber,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Gladiator artwork
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              classImageAsset,
                              fit: BoxFit.cover,
                            ),
                            // Defending visual indicator
                            if (controller.isDefending.value)
                              Container(
                                color: Colors.blue.withValues(alpha: 0.2),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.shield,
                                  color: Colors.cyanAccent,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Small text label
                      Container(
                        color: const Color(0xFF1C140E),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        alignment: Alignment.center,
                        child: Text(
                          'YOU',
                          style: VitruvianTypography.serifTitle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                // Shift Lane button overlay (arrow pointing up or down)
                if (controller.isPlayerTurn.value && !controller.hasMovedThisTurn.value && controller.playerAp.value >= 1)
                  Positioned(
                    left: -32,
                    top: 36,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFC89B5D),
                      child: IconButton(
                        icon: Icon(
                          isFront ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 12,
                          color: Colors.black,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: controller.playerMove,
                        tooltip: 'Shift lane (Costs 1 AP)',
                      ),
                    ),
                  ),

                // Floating Damage / Heal Popups
                if (controller.damagePopups.containsKey('player'))
                  Positioned(
                    top: -24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        controller.damagePopups['player']!,
                        style: VitruvianTypography.monospaceData(
                          fontSize: 16,
                          color: controller.damagePopups['player']!.contains('-')
                              ? const Color(0xFFFF5555)
                              : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Bottom Control HUD Deck
  Widget _buildBottomHudDeck(
    BuildContext context,
    CombatController controller,
    bool isPlayerTurn,
    int playerHp,
    int playerMaxHp,
    int playerStamina,
    int playerMaxStamina,
    int playerAp,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0A08),
        border: Border(top: BorderSide(color: Color(0xFF2A2218), width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HP, Stamina progress bars, and AP gems
          Row(
            children: [
              // HP HUD
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('HP',
                            style: VitruvianTypography.monospaceData(
                                fontSize: 10, color: const Color(0xFFDCD4C8))),
                        Text('$playerHp/$playerMaxHp',
                            style: VitruvianTypography.monospaceData(
                                fontSize: 10, color: const Color(0xFFDCD4C8))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: playerHp / playerMaxHp,
                      backgroundColor: const Color(0xFF220A0A),
                      valueColor: const AlwaysStoppedAnimation<Color>(VitruvianColors.rustBlood),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Action Points (AP) - 3 Gems in the center
              Column(
                children: [
                  Text('AP',
                      style: VitruvianTypography.monospaceData(
                        fontSize: 9,
                        color: VitruvianColors.sepiaUmber,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(3, (index) {
                      bool isActive = playerAp > index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFFC89B5D)
                                : const Color(0xFF1E1710),
                            border: Border.all(
                              color: isActive ? Colors.white70 : const Color(0xFF3E3224),
                              width: 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFC89B5D).withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    )
                                  ]
                                : [],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Stamina HUD
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('STAM',
                            style: VitruvianTypography.monospaceData(
                                fontSize: 10, color: const Color(0xFFDCD4C8))),
                        Text('$playerStamina/$playerMaxStamina',
                            style: VitruvianTypography.monospaceData(
                                fontSize: 10, color: const Color(0xFFDCD4C8))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: playerStamina / playerMaxStamina,
                      backgroundColor: const Color(0xFF1A1A10),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B8000)),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // The Three Buttons: ATTACK, DEFENSE, ITEMS
          Row(
            children: [
              // 1. Attack Button
              Expanded(
                child: _buildCombatButton(
                  title: 'ATTACK',
                  subtitle: 'Execute active skill',
                  icon: Icons.flash_on,
                  borderColor: isPlayerTurn && playerAp > 0 ? VitruvianColors.rustBlood : const Color(0xFF2C1C1C),
                  colorText: isPlayerTurn && playerAp > 0 ? const Color(0xFFFFAAAA) : Colors.white24,
                  onTap: isPlayerTurn && playerAp > 0
                      ? () => _showSkillBottomSheet(context, controller)
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              // 2. Defense Button
              Expanded(
                child: _buildCombatButton(
                  title: 'DEFEND',
                  subtitle: 'Shield & +45 Stamina',
                  icon: Icons.shield,
                  borderColor: isPlayerTurn && playerAp > 0 ? VitruvianColors.sepiaUmber : const Color(0xFF201B15),
                  colorText: isPlayerTurn && playerAp > 0 ? const Color(0xFFE4DCD0) : Colors.white24,
                  onTap: isPlayerTurn && playerAp > 0 ? controller.playerDefense : null,
                ),
              ),
              const SizedBox(width: 10),

              // 3. Items Button
              Expanded(
                child: _buildCombatButton(
                  title: 'ITEMS',
                  subtitle: 'Use inventory flask',
                  icon: Icons.healing,
                  borderColor: isPlayerTurn && playerAp > 0 ? const Color(0xFF1F3535) : const Color(0xFF121E1E),
                  colorText: isPlayerTurn && playerAp > 0 ? Colors.cyanAccent : Colors.white24,
                  onTap: isPlayerTurn && playerAp > 0
                      ? () => _showItemsBottomSheet(context, controller)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Combat Custom deck button (Icon only to prevent overflow)
  Widget _buildCombatButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color borderColor,
    required Color colorText,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: '$title: $subtitle',
      textStyle: VitruvianTypography.monospaceData(fontSize: 11, color: Colors.black),
      decoration: const BoxDecoration(
        color: VitruvianColors.agedBone,
        borderRadius: BorderRadius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        child: EtchedContainer(
          padding: const EdgeInsets.symmetric(vertical: 12),
          borderColor: borderColor,
          backgroundColor: const Color(0xFF0F0C0A),
          child: Icon(
            icon,
            size: 22,
            color: colorText,
          ),
        ),
      ),
    );
  }

  // Skill Selection Bottom Sheet
  void _showSkillBottomSheet(BuildContext context, CombatController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0E0C0A),
          border: Border(
            top: BorderSide(color: Color(0xFF2A2218), width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CHOOSE COMBAT SKILL',
              style: VitruvianTypography.serifTitle(fontSize: 16, color: VitruvianColors.sepiaUmber),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Skill 1
            _buildSkillListItem(
              name: 'Skill 1: Blood Falchion Strike',
              desc: 'Inflicts 15-22 physical damage. Deals +50% damage if you are in the Front Line. Deals -30% from the Back Line.',
              ap: 1,
              stamina: 20,
              isEnabled: controller.playerStamina.value >= 20,
              onTap: () {
                Get.back(); // close sheet
                controller.playerAttack(1);
              },
            ),
            const SizedBox(height: 12),

            // Skill 2
            _buildSkillListItem(
              name: 'Skill 2: Hermetic Firebolt',
              desc: 'Launches alchemical plasma dealing 25-35 magical fire damage. Fully effective from any lane position.',
              ap: 1,
              stamina: 40,
              isEnabled: controller.playerStamina.value >= 40,
              onTap: () {
                Get.back(); // close sheet
                controller.playerAttack(2);
              },
            ),
            const SizedBox(height: 16),

            // Close
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1710),
                foregroundColor: VitruvianColors.agedBone,
                side: const BorderSide(color: Color(0xFF382C1F)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                'CANCEL',
                style: VitruvianTypography.monospaceData(fontSize: 12),
              ),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillListItem({
    required String name,
    required String desc,
    required int ap,
    required int stamina,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: EtchedContainer(
        padding: const EdgeInsets.all(12),
        borderColor: isEnabled ? const Color(0xFF382C1F) : const Color(0xFF1F1212),
        backgroundColor: isEnabled ? const Color(0xFF16120E) : const Color(0xFF0F0B0B),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: VitruvianTypography.serifTitle(
                      fontSize: 14,
                      color: isEnabled ? VitruvianColors.agedBone : Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: VitruvianTypography.serifBody(
                      fontSize: 12,
                      color: isEnabled ? const Color(0xFF888078) : Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$ap AP',
                  style: VitruvianTypography.monospaceData(
                    fontSize: 12,
                    color: isEnabled ? const Color(0xFFC89B5D) : Colors.white24,
                  ),
                ),
                Text(
                  '$stamina STAM',
                  style: VitruvianTypography.monospaceData(
                    fontSize: 10,
                    color: isEnabled ? const Color(0xFF8B8000) : Colors.white12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Items Selection Bottom Sheet
  void _showItemsBottomSheet(BuildContext context, CombatController controller) {
    final invState = Get.find<InventoryState>();
    final consumables = invState.ledger.where((item) => item.category == ItemCategory.consumable).toList();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0E0C0A),
          border: Border(
            top: BorderSide(color: Color(0xFF2A2218), width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'INVENTORY POTIONS & ELIXIRS',
              style: VitruvianTypography.serifTitle(fontSize: 16, color: Colors.cyanAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            if (consumables.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'No usable consumables in inventory.',
                  style: VitruvianTypography.serifBody(
                    fontSize: 14,
                    color: Colors.white24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (consumables.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: consumables.length,
                  itemBuilder: (context, index) {
                    final item = consumables[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: InkWell(
                        onTap: () {
                          Get.back(); // close sheet
                          controller.useCombatItem(item);
                        },
                        child: EtchedContainer(
                          padding: const EdgeInsets.all(12),
                          borderColor: const Color(0xFF1E3535),
                          backgroundColor: const Color(0xFF0F1B1B),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.name} (x${item.count})',
                                      style: VitruvianTypography.serifTitle(
                                        fontSize: 14,
                                        color: VitruvianColors.agedBone,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: VitruvianTypography.serifBody(
                                        fontSize: 12,
                                        color: const Color(0xFF7BA6A6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'USE (1 AP)',
                                style: VitruvianTypography.monospaceData(
                                  fontSize: 11,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1710),
                foregroundColor: VitruvianColors.agedBone,
                side: const BorderSide(color: Color(0xFF382C1F)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                'CANCEL',
                style: VitruvianTypography.monospaceData(fontSize: 12),
              ),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  // Defeat Overlay Screen
  Widget _buildDefeatOverlay(CombatController controller) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.heart_broken,
              color: VitruvianColors.rustBlood,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'YOU FELL PAST THE VEIL',
              style: VitruvianTypography.serifTitle(
                fontSize: 26,
                color: VitruvianColors.rustBlood,
              ).copyWith(letterSpacing: 2.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The subterranean shadows of the undercroft consume your essence. The werewolves continue their rhythmic clicking...',
              style: VitruvianTypography.serifBody(
                fontSize: 15,
                color: const Color(0xFF8C7D73),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E1212),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => controller.startCombat('combat_crypt_werewolves'), // restart
                    child: Text(
                      'RETRY CONFLICT',
                      style: VitruvianTypography.monospaceData(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF151310),
                      foregroundColor: VitruvianColors.agedBone,
                      side: const BorderSide(color: Color(0xFF3C3224)),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => controller.escapeCombat(), // flee
                    child: Text(
                      'RETREAT TO SANCTUARY',
                      style: VitruvianTypography.monospaceData(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Victory Overlay Screen
  Widget _buildVictoryOverlay(CombatController controller) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.stars,
              color: Color(0xFFC89B5D),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'THE FOE VANQUISHED',
              style: VitruvianTypography.serifTitle(
                fontSize: 26,
                color: const Color(0xFFC89B5D),
              ).copyWith(letterSpacing: 2.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The lupine monsters dissolve into the ancient stone floor. Silence returns to the scriptorium chamber. Your blades drip with black bile.',
              style: VitruvianTypography.serifBody(
                fontSize: 15,
                color: const Color(0xFF8C7D73),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3A4E3A)),
                color: const Color(0xFF132213),
              ),
              child: Text(
                '+50 XP REWARDED',
                style: VitruvianTypography.monospaceData(
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC89B5D),
                  foregroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  controller.inCombat.value = false; // exit combat view
                },
                child: Text(
                  'COLLECT TROPHIES & TRAVERSE',
                  style: VitruvianTypography.monospaceData(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
