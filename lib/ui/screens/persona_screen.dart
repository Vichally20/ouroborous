import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/combat_stats.dart';
import '../../models/item.dart';
import '../../states/player_state.dart';

class PersonaScreen extends StatelessWidget {
  const PersonaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerState = Get.find<PlayerState>();

    return Obx(() {
      final activeHero = playerState.heroes[playerState.activeHeroIndex.value];
      final loadout = playerState.loadout.value;
      final currentClass = playerState.characterClass.value;

      // Same numbers combat uses (attributes + equipment + talents).
      final stats = HeroCombatStats.of(activeHero);
      final (hitDmg, critDmg) = stats.strikeDamage();
      final perkStr = stats.weaponPerks.isEmpty
          ? 'None'
          : stats.weaponPerks.map((p) => p.replaceAll('_', ' ')).join(', ');

      final classImageAsset = activeHero.portrait;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Balance notification icon
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        activeHero.name.toUpperCase(),
                        style: VitruvianTypography.serifTitle(
                          fontSize: 22,
                          color: const Color(0xFFE0C8B0),
                        ).copyWith(letterSpacing: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentClass.title
                            .toUpperCase()
                            .replaceAll('-SCRIBE', '')
                            .replaceAll('SCRIBE', ''),
                        style: VitruvianTypography.serifBody(
                          fontSize: 12,
                          color: const Color(0xFFC89B5D),
                        ).copyWith(letterSpacing: 3.0),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: VitruvianColors.sepiaUmber),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // VITRUVIAN MAN IMAGE & EQUIPMENT SLOTS
            Container(
              height: 380,
              decoration: const BoxDecoration(
                color: Color(0xFF0C0A08),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.35,
                    child: Image.asset(
                      classImageAsset,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 380,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSlotTile(context, playerState, 'HEAD', AnatomicalSlot.head, loadout.head, Icons.sports_martial_arts),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSlotTile(context, playerState, 'SECONDARY HAND', AnatomicalSlot.secondaryHand, loadout.secondaryHand, Icons.shield_outlined),
                          _buildSlotTile(context, playerState, 'CHEST', AnatomicalSlot.chest, loadout.chest, Icons.health_and_safety_outlined),
                          _buildSlotTile(context, playerState, 'MAIN HAND', AnatomicalSlot.mainHand, loadout.mainHand, Icons.colorize_outlined),
                        ],
                      ),
                      _buildSlotTile(context, playerState, 'LEG', AnatomicalSlot.leg, loadout.leg, Icons.directions_walk),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // LOADOUT SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'L O A D O U T',
                  style: VitruvianTypography.serifTitle(
                    fontSize: 18,
                    color: const Color(0xFFC89B5D),
                  ).copyWith(letterSpacing: 2.0),
                ),
                Text(
                  'WEIGHT: ${loadout.totalEquippedWeight.toStringAsFixed(1)} / ${playerState.maxWeightCapacity.value.toStringAsFixed(0)}',
                  style: VitruvianTypography.monospaceData(
                    fontSize: 12,
                    color: const Color(0xFF8A7A68),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF2A2218), thickness: 1),
            const SizedBox(height: 8),

            _buildLoadoutRow('Strike Damage', '$hitDmg (crit $critDmg)'),
            _buildLoadoutRow('Armour', '${stats.defense}'),
            _buildLoadoutRow('Strength', '${stats.strength}'),
            _buildLoadoutRow('Speed', '${stats.speed}'),
            _buildLoadoutRow('Weapon Perks', perkStr, valColor: const Color(0xFFC89B5D)),
            const SizedBox(height: 16),
            
            // Hero Description Callout Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0A08),
                border: Border.all(color: const Color(0xFF2A2218), width: 1.0),
              ),
              child: Text(
                activeHero.description,
                style: VitruvianTypography.serifBody(
                  fontSize: 13,
                  color: const Color(0xFF8A7A68),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // CHARACTER SELECTION ROSTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(playerState.heroes.length, (index) {
                final hero = playerState.heroes[index];
                final firstName = hero.name.split(' ').first;
                return _buildCharacterBtn(firstName, index, playerState);
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  Widget _buildSlotTile(
    BuildContext context,
    PlayerState playerState,
    String name,
    AnatomicalSlot slot,
    ArtifactItem? item,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: item == null ? null : () => _confirmUnequip(context, playerState, slot, item),
      child: Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF151310).withValues(alpha: 0.92),
            border: Border.all(
              color: item != null ? const Color(0xFFC89B5D) : const Color(0xFF3A2C20),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: item != null ? const Color(0xFFC89B5D) : const Color(0xFF8A7A68),
              ),
              if (item != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    item.displayName,
                    style: VitruvianTypography.monospaceData(fontSize: 8, color: VitruvianColors.agedBone),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (item != null)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFC89B5D),
              shape: BoxShape.circle,
            ),
          ),
      ],
    ),
    );
  }

  void _confirmUnequip(BuildContext context, PlayerState playerState, AnatomicalSlot slot, ArtifactItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151310),
      shape: const RoundedRectangleBorder(side: BorderSide(color: Color(0xFF3A2C20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.displayName.toUpperCase(),
                  style: VitruvianTypography.serifTitle(fontSize: 18, color: const Color(0xFFE0C8B0))),
              const SizedBox(height: 6),
              Text(item.description,
                  style: VitruvianTypography.serifBody(fontSize: 14, color: VitruvianColors.agedBone)),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC89B5D),
                  side: const BorderSide(color: Color(0xFFC89B5D)),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  playerState.unequipArtifact(slot);
                },
                child: Text('UNEQUIP TO INVENTORY', style: VitruvianTypography.serifTitle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadoutRow(String label, String value, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
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
            value,
            style: VitruvianTypography.monospaceData(
              fontSize: 15,
              color: valColor ?? const Color(0xFFE0C8B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterBtn(String label, int index, PlayerState playerState) {
    final isSelected = playerState.activeHeroIndex.value == index;
    return InkWell(
      onTap: () => playerState.selectHero(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A2C20) : const Color(0xFF151310),
          border: Border.all(color: isSelected ? const Color(0xFFC89B5D) : const Color(0xFF2A2218)),
        ),
        child: Text(
          label,
          style: VitruvianTypography.serifBody(
            fontSize: 12,
            color: isSelected ? VitruvianColors.agedBone : Colors.grey,
          ),
        ),
      ),
    );
  }
}
