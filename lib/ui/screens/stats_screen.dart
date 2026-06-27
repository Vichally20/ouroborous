import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/player_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerState = Get.find<PlayerState>();

    return Obx(() {
      final vitals = playerState.vitals.value;
      final attr = playerState.attributes.value;
      final res = playerState.resistances.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // VITALS SECTION
            Text(
              'V I T A L S',
              style: VitruvianTypography.serifTitle(
                fontSize: 16,
                color: VitruvianColors.agedBone,
              ).copyWith(letterSpacing: 4.0),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF2A2218), thickness: 1),
            const SizedBox(height: 12),

            _buildVitalBar(
              label: 'HP',
              current: vitals.currentHp,
              max: vitals.maxHp,
              color: const Color(0xFFE53935),
            ),
            _buildVitalBar(
              label: 'Mana',
              current: vitals.currentMana,
              max: vitals.maxMana,
              color: const Color(0xFF00ACC1),
            ),
            _buildVitalBar(
              label: 'Stamina',
              current: vitals.currentStamina,
              max: vitals.maxStamina,
              color: const Color(0xFFC89B5D),
            ),
            _buildVitalBar(
              label: 'Sanity',
              current: vitals.currentSanity,
              max: vitals.maxSanity,
              color: VitruvianColors.agedBone,
            ),
            const SizedBox(height: 24),

            // ATTRIBUTES SECTION
            Text(
              'A T T R I B U T E S',
              style: VitruvianTypography.serifTitle(
                fontSize: 16,
                color: VitruvianColors.agedBone,
              ).copyWith(letterSpacing: 4.0),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF2A2218), thickness: 1),
            const SizedBox(height: 12),

            _buildAttributeRow('Strength', attr.strength),
            _buildAttributeRow('Dexterity', attr.dexterity),
            _buildAttributeRow('Intelligence', attr.intelligence),
            _buildAttributeRow('Constitution', attr.constitution),
            _buildAttributeRow('Insight', attr.insight),
            const SizedBox(height: 24),

            // RESISTANCES SECTION
            Text(
              'R E S I S T A N C E S',
              style: VitruvianTypography.serifTitle(
                fontSize: 16,
                color: VitruvianColors.agedBone,
              ).copyWith(letterSpacing: 4.0),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF2A2218), thickness: 1),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  _buildResistanceCol('Physical', res.physical),
                  const SizedBox(width: 24),
                  _buildResistanceCol('Bleed', res.bleed, valueColor: const Color(0xFFE53935)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  _buildResistanceCol('Blight', res.poison),
                  const SizedBox(width: 24),
                  _buildResistanceCol('Horror', res.madness),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    });
  }

  Widget _buildVitalBar({
    required String label,
    required int current,
    required int max,
    required Color color,
  }) {
    final progress = max == 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: VitruvianTypography.monospaceData(fontSize: 14, color: VitruvianColors.agedBone),
              ),
              Text(
                '$current/$max',
                style: VitruvianTypography.monospaceData(fontSize: 14, color: VitruvianColors.agedBone),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.isNaN ? 0 : progress,
            backgroundColor: const Color(0xFF1E1C18),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(String label, int value) {
    final valStr = value.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label, style: VitruvianTypography.serifBody(fontSize: 16, color: VitruvianColors.agedBone)),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dotCount = (constraints.maxWidth / 5).floor();
                return Text(
                  '.' * dotCount,
                  style: const TextStyle(color: Color(0xFF2A2218), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valStr,
            style: VitruvianTypography.monospaceData(
              fontSize: 15,
              color: const Color(0xFFC89B5D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResistanceCol(String label, int val, {Color? valueColor}) {
    final valStr = '${val.toString().padLeft(2, '0')}%';
    return Expanded(
      child: Row(
        children: [
          Text(label, style: VitruvianTypography.serifBody(fontSize: 15, color: const Color(0xFF8A7A68))),
          const SizedBox(width: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dotCount = (constraints.maxWidth / 5).floor();
                return Text(
                  '.' * dotCount,
                  style: const TextStyle(color: Color(0xFF2A2218), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Text(
            valStr,
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
