import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../models/item.dart';
import '../ui/widgets/etched_container.dart';
import '../ui/screens/combat_screen.dart';
import '../states/combat_state.dart';
import 'sandbox_dungeon_controller.dart';

class SandboxDungeonScreen extends StatelessWidget {
  const SandboxDungeonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Register controller scoped to this screen
    final controller = Get.put(SandboxDungeonController());

    return Scaffold(
      backgroundColor: VitruvianColors.voidBlack,
      body: SafeArea(
        child: Obx(() {
          final combatController = Get.find<CombatController>();
          if (controller.phase.value == 'setup' || !combatController.inCombat.value) {
            if (controller.phase.value != 'setup') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.phase.value = 'setup';
              });
            }
            return _buildSetupPanel(context, controller);
          } else {
            return const CombatScreen();
          }
        }),
      ),
    );
  }

  // ─── SETUP PHASE PANEL ───
  Widget _buildSetupPanel(BuildContext context, SandboxDungeonController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF15120E),
            border: Border(bottom: BorderSide(color: Color(0xFF3A2C20), width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ISLAND OF SKULLS: SANDBOX DUNGEON',
                            style: VitruvianTypography.serifTitle(fontSize: 16, color: const Color(0xFFE0C8B0)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Infinite 30-Wave Proving Grounds & Attribute Scaler',
                            style: VitruvianTypography.monospaceData(fontSize: 10, color: Colors.amberAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Return to Overworld Map',
              ),
            ],
          ),
        ),

        // Main Config Setup Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Obx(() {
                final isNarrow = constraints.maxWidth < 800;

                final leftCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('1. ARCHETYPE SELECTION'),
                    const SizedBox(height: 8),
                    if (c.availableHeroes.isEmpty)
                      EtchedContainer(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No heroes in roster. Using default Gladiator base template.',
                          style: VitruvianTypography.serifBody(color: Colors.white70),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(c.availableHeroes.length, (index) {
                          final hero = c.availableHeroes[index];
                          final isSel = c.selectedHeroIndex.value == index;
                          return InkWell(
                            onTap: () => c.selectHero(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              width: 220,
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF2E2214) : const Color(0xFF100E0C),
                                border: Border.all(
                                  color: isSel ? Colors.amberAccent : const Color(0xFF3A2C20),
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hero.name,
                                    style: VitruvianTypography.serifTitle(
                                        fontSize: 15, color: isSel ? Colors.amberAccent : Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hero.subtitle,
                                    style: VitruvianTypography.monospaceData(fontSize: 10, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('2. WEAPON & LOADOUT TESTING'),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(c.availableWeapons.length, (wIdx) {
                        final weapon = c.availableWeapons[wIdx];
                        final isSel = c.selectedWeaponIndex.value == wIdx;
                        return InkWell(
                          onTap: () => c.selectedWeaponIndex.value = wIdx,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF2E2214) : const Color(0xFF100E0C),
                              border: Border.all(
                                color: isSel ? Colors.amberAccent : const Color(0xFF3A2C20),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  weapon.weaponRange == WeaponRange.ranged ? Icons.auto_awesome : Icons.shield_outlined,
                                  color: isSel ? Colors.amberAccent : Colors.white54,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            weapon.name,
                                            style: VitruvianTypography.serifTitle(
                                                fontSize: 15, color: isSel ? Colors.amberAccent : Colors.white),
                                          ),
                                          Text(
                                            '+${weapon.statBonus} STAT BONUS',
                                            style: VitruvianTypography.monospaceData(
                                                fontSize: 11, color: Colors.cyanAccent),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        weapon.description,
                                        style: VitruvianTypography.serifBody(fontSize: 13, color: Colors.white70),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: weapon.perks.map((perk) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3E1212),
                                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                                            ),
                                            child: Text(
                                              perk.toUpperCase(),
                                              style: VitruvianTypography.monospaceData(
                                                  fontSize: 9, color: Colors.redAccent),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );

                final rightCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('3. LIVE ATTRIBUTE TUNER'),
                    const SizedBox(height: 8),
                    EtchedContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Adjust core parameters to test damage output & vital scaling against Wave 1-30 bestiary.',
                            style: VitruvianTypography.serifBody(fontSize: 13, color: Colors.white60),
                          ),
                          const Divider(color: Color(0xFF3A2C20), height: 24),
                          _buildAttrStepper('STRENGTH (STR)', 'STR', c.strength.value, c),
                          _buildAttrStepper('DEXTERITY (DEX)', 'DEX', c.dexterity.value, c),
                          _buildAttrStepper('INTELLIGENCE (INT)', 'INT', c.intelligence.value, c),
                          _buildAttrStepper('CONSTITUTION (CON)', 'CON', c.constitution.value, c),
                          _buildAttrStepper('INSIGHT (INS)', 'INS', c.insight.value, c),
                          const Divider(color: Color(0xFF3A2C20), height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF15120E),
                              border: Border.all(color: const Color(0xFFC89B5D)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COMPUTED SCALING VITALS:',
                                  style: VitruvianTypography.monospaceData(fontSize: 11, color: Colors.amberAccent),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('MAX HEALTH:', style: VitruvianTypography.serifTitle(fontSize: 14)),
                                    Text('${c.maxHp.value} HP',
                                        style: VitruvianTypography.monospaceData(fontSize: 14, color: Colors.redAccent)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('MAX STAMINA:', style: VitruvianTypography.serifTitle(fontSize: 14)),
                                    Text('${c.maxStamina.value} STAM',
                                        style: VitruvianTypography.monospaceData(fontSize: 14, color: Colors.greenAccent)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF662222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                      ),
                      icon: const Icon(Icons.flash_on, color: Colors.amberAccent),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ENTER SANDBOX ARENA (WAVES 1-30)',
                          style: VitruvianTypography.monospaceData(fontSize: 13, color: Colors.amberAccent),
                        ),
                      ),
                      onPressed: () => c.startDungeonRun(),
                    ),
                  ],
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            leftCol,
                            const SizedBox(height: 24),
                            rightCol,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: leftCol),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: rightCol),
                          ],
                        ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttrStepper(String label, String keyName, int value, SandboxDungeonController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 6,
        children: [
          Text(label, style: VitruvianTypography.serifTitle(fontSize: 13, color: VitruvianColors.agedBone)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepButton('-5', () => c.adjustAttribute(keyName, -5)),
              _buildStepButton('-1', () => c.adjustAttribute(keyName, -1)),
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: VitruvianTypography.monospaceData(fontSize: 14, color: Colors.amberAccent),
                ),
              ),
              _buildStepButton('+1', () => c.adjustAttribute(keyName, 1)),
              _buildStepButton('+5', () => c.adjustAttribute(keyName, 5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2218),
          border: Border.all(color: const Color(0xFF3A2C20)),
        ),
        child: Text(text, style: VitruvianTypography.monospaceData(fontSize: 11, color: Colors.white)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: VitruvianTypography.monospaceData(fontSize: 12, color: Colors.amberAccent),
    );
  }
}
