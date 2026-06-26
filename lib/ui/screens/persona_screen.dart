import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/character_class.dart';
import '../../models/item.dart';
import '../../states/player_state.dart';
import '../widgets/etched_container.dart';

class PersonaScreen extends StatelessWidget {
  final PlayerState playerState;

  const PersonaScreen({super.key, required this.playerState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, child) {
        final loadout = playerState.loadout;
        final vitals = playerState.vitals;
        final currentClass = playerState.characterClass;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Class Identification & Level Header
              EtchedContainer(
                borderColor: VitruvianColors.sepiaUmber,
                child: Column(
                  children: [
                    Text(
                      '${currentClass.title.toUpperCase()} [LVL ${playerState.level}]',
                      style: VitruvianTypography.serifTitle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentClass.clinicalRationale,
                      style: VitruvianTypography.serifBody(
                        fontSize: 14,
                        color: VitruvianColors.sepiaUmber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Vitals, XP Tracker & Encumbrance Status
              EtchedContainer(
                child: Column(
                  children: [
                    _buildStatusBar(
                      label: 'PHYSICAL INTEGRITY (HP)',
                      value: '${vitals.currentHp}/${vitals.maxHp}',
                      progress: vitals.currentHp / vitals.maxHp,
                      color: VitruvianColors.agedBone,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBar(
                      label: 'HERMETIC MANA',
                      value: '${vitals.currentMana}/${vitals.maxMana}',
                      progress: vitals.currentMana / vitals.maxMana,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBar(
                      label: 'CLINICAL XP PROGRESSION',
                      value: '${playerState.currentXp}/${playerState.xpToNextLevel} XP',
                      progress: playerState.currentXp / playerState.xpToNextLevel,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBar(
                      label: 'ENCUMBRANCE TRACKING',
                      value:
                          '${loadout.totalEquippedWeight.toStringAsFixed(1)}/${playerState.maxWeightCapacity.toStringAsFixed(0)} KG',
                      progress: (loadout.totalEquippedWeight /
                              playerState.maxWeightCapacity)
                          .clamp(0.0, 1.0),
                      color: playerState.isEncumbered
                          ? VitruvianColors.rustBlood
                          : VitruvianColors.sepiaUmber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Centralized Body-Map Vitruvian Schematic (Head, Chest, Leg, Main Hand, Secondary Hand)
              EtchedContainer(
                height: 380,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.15,
                      child: Icon(
                        Icons.accessibility_new,
                        size: 280,
                        color: VitruvianColors.agedBone,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSlotTile('HEAD', loadout.head, Icons.psychology),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSlotTile('SECONDARY HAND', loadout.secondaryHand, Icons.shield),
                            _buildSlotTile('CHEST', loadout.chest, Icons.favorite),
                            _buildSlotTile('MAIN HAND', loadout.mainHand, Icons.colorize),
                          ],
                        ),
                        _buildSlotTile('LEG', loadout.leg, Icons.nordic_walking),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // XP Demo Button & Class Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () => playerState.gainXp(35),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF201B10),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: Text('+35 XP [TEST]', style: VitruvianTypography.monospaceData(fontSize: 11, color: Colors.amberAccent)),
                    ),
                  ),
                  _buildClassBtn('Warrior', PersonalityClass.warrior),
                  _buildClassBtn('Sorcerer', PersonalityClass.sorcerer),
                  _buildClassBtn('Assassin', PersonalityClass.assassin),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar({
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: VitruvianTypography.monospaceData(fontSize: 11)),
            Text(value, style: VitruvianTypography.monospaceData(fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.isNaN ? 0 : progress,
          backgroundColor: VitruvianColors.etchedHairline,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildSlotTile(String name, ArtifactItem? item, IconData icon) {
    return EtchedContainer(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      borderColor: item != null ? VitruvianColors.sepiaUmber : VitruvianColors.etchedHairline,
      backgroundColor: item != null ? const Color(0xFF151310) : VitruvianColors.voidBlack,
      child: Column(
        children: [
          Icon(icon, size: 20, color: item != null ? VitruvianColors.sepiaUmber : Colors.grey),
          const SizedBox(height: 4),
          Text(
            name,
            style: VitruvianTypography.monospaceData(fontSize: 8, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            item?.name ?? '[EMPTY]',
            style: VitruvianTypography.serifBody(
              fontSize: 11,
              color: item != null ? VitruvianColors.agedBone : Colors.white24,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClassBtn(String title, PersonalityClass pClass) {
    final isSelected = playerState.characterClass.type == pClass.type;
    return InkWell(
      onTap: () => playerState.setClass(pClass),
      child: EtchedContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderColor: isSelected ? VitruvianColors.sepiaUmber : VitruvianColors.etchedHairline,
        backgroundColor: isSelected ? const Color(0xFF201B15) : VitruvianColors.voidBlack,
        child: Text(
          title,
          style: VitruvianTypography.serifBody(
            fontSize: 12,
            color: isSelected ? VitruvianColors.agedBone : Colors.grey,
          ),
        ),
      ),
    );
  }
}
