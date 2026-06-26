import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/player_state.dart';
import '../widgets/etched_container.dart';

class StatsScreen extends StatelessWidget {
  final PlayerState playerState;

  const StatsScreen({super.key, required this.playerState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, child) {
        final vitals = playerState.vitals;
        final attr = playerState.attributes;
        final res = playerState.resistances;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CLINICAL LEDGER OF CAPABILITIES',
                  style: VitruvianTypography.serifTitle(fontSize: 18)),
              const SizedBox(height: 12),

              // Progression Tracker
              EtchedContainer(
                borderColor: Colors.amberAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('0. CLINICAL PROGRESSION',
                        style: VitruvianTypography.serifTitle(
                            fontSize: 14, color: Colors.amberAccent)),
                    const Divider(),
                    _buildLedgerRow('Anatomical Mastery Level', 'LVL ${playerState.level}', valueColor: Colors.amberAccent),
                    _buildLedgerRow('Experience (XP) Recorded', '${playerState.currentXp} / ${playerState.xpToNextLevel} XP'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Vitals Ledger (HP, Mana, Stamina, Sanity)
              EtchedContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('I. VITALS',
                        style: VitruvianTypography.serifTitle(
                            fontSize: 14, color: VitruvianColors.sepiaUmber)),
                    const Divider(),
                    _buildLedgerRow('Physical Integrity (HP)', '${vitals.currentHp} / ${vitals.maxHp}'),
                    _buildLedgerRow('Hermetic Mana (MP)', '${vitals.currentMana} / ${vitals.maxMana}', valueColor: Colors.cyanAccent),
                    _buildLedgerRow('Metabolic Stamina', '${vitals.currentStamina} / ${vitals.maxStamina}'),
                    _buildLedgerRow(
                      'Cerebral Sanity',
                      '${vitals.currentSanity} / ${vitals.maxSanity}',
                      valueColor: vitals.isSanityDepleted ? VitruvianColors.rustBlood : VitruvianColors.agedBone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Core Attributes
              EtchedContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('II. CORE ATTRIBUTES',
                        style: VitruvianTypography.serifTitle(
                            fontSize: 14, color: VitruvianColors.sepiaUmber)),
                    const Divider(),
                    _buildLedgerRow('STR [Muscular Force]', '${attr.strength}'),
                    _buildLedgerRow('DEX [Vascular Precision]', '${attr.dexterity}'),
                    _buildLedgerRow('INT [Hermetic Knowledge]', '${attr.intelligence}'),
                    _buildLedgerRow('CON [Skeletal Density]', '${attr.constitution}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Resistances
              EtchedContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('III. PATHOLOGICAL RESISTANCES',
                        style: VitruvianTypography.serifTitle(
                            fontSize: 14, color: VitruvianColors.sepiaUmber)),
                    const Divider(),
                    _buildLedgerRow('Physical Impact', '${res.physical}%'),
                    _buildLedgerRow('Hemorrhagic Bleed', '${res.bleed}%'),
                    _buildLedgerRow('Botanical Poison', '${res.poison}%'),
                    _buildLedgerRow('Cerebral Madness', '${res.madness}%'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerRow(String label, String val, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: VitruvianTypography.serifBody(fontSize: 15)),
          Text(
            val,
            style: VitruvianTypography.monospaceData(
              fontSize: 14,
              color: valueColor ?? VitruvianColors.agedBone,
            ),
          ),
        ],
      ),
    );
  }
}
