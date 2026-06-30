import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/item.dart';
import '../../models/weapon_perk.dart';
import '../../states/inventory_state.dart';
import '../../states/player_state.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryState = Get.find<InventoryState>();
    final playerState = Get.find<PlayerState>();

    return Obx(() {
      final allItems = inventoryState.items;

      final currencies = allItems.where((i) => i.category == ItemCategory.currency).toList();
      final weapons = allItems.where((i) => i.category == ItemCategory.weapon).toList();
      final apparel = allItems.where((i) => i.category == ItemCategory.apparel).toList();
      final consumables = allItems.where((i) => i.category == ItemCategory.consumable).toList();
      final misc = allItems.where((i) => i.category == ItemCategory.miscellaneous).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTIONS IN REQUESTED ORDER
            _buildSection(context, 'Currency', Icons.monetization_on_outlined, currencies, playerState, inventoryState),
            _buildSection(context, 'Weapons', Icons.sports_martial_arts, weapons, playerState, inventoryState),
            _buildSection(context, 'Apparel', Icons.shield_outlined, apparel, playerState, inventoryState),
            _buildSection(context, 'Consumables', Icons.local_pharmacy_outlined, consumables, playerState, inventoryState),
            _buildSection(context, 'Miscellaneous', Icons.key_outlined, misc, playerState, inventoryState),
          ],
        ),
      );
    });
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<ArtifactItem> items,
    PlayerState playerState,
    InventoryState inventoryState,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFFC89B5D)),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: VitruvianTypography.serifTitle(
                  fontSize: 17,
                  color: VitruvianColors.agedBone,
                ).copyWith(letterSpacing: 2.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2A2218), thickness: 1),
          const SizedBox(height: 6),
          ...items.map((item) => _buildLedgerRow(context, item, playerState, inventoryState)),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(
    BuildContext context,
    ArtifactItem item,
    PlayerState playerState,
    InventoryState inv,
  ) {
    final isItalic = item.id.contains('2') || item.id == 'ap1';
    final weightStr = item.category == ItemCategory.currency ? '' : '${item.weight.toStringAsFixed(2)}kg';
    final countStr = item.category == ItemCategory.currency ? '${item.count}' : 'x${item.count}';

    return InkWell(
      onTap: () => _handleItemClick(context, item, playerState, inv),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Text(
              item.name,
              style: VitruvianTypography.serifBody(
                fontSize: 15,
                color: VitruvianColors.agedBone,
              ).copyWith(fontStyle: isItalic ? FontStyle.italic : FontStyle.normal),
            ),
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
              countStr,
              style: VitruvianTypography.monospaceData(fontSize: 13, color: VitruvianColors.agedBone),
            ),
            if (weightStr.isNotEmpty) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 58,
                child: Text(
                  weightStr,
                  style: VitruvianTypography.monospaceData(
                    fontSize: 13,
                    color: const Color(0xFF8A7A68),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleItemClick(
    BuildContext context,
    ArtifactItem item,
    PlayerState playerState,
    InventoryState inv,
  ) {
    if (item.category == ItemCategory.currency) return;

    String actionLabel = 'USE';
    if (item.category == ItemCategory.weapon) actionLabel = 'ARM';
    if (item.category == ItemCategory.apparel) actionLabel = 'WEAR';
    if (item.category == ItemCategory.consumable) actionLabel = 'CONSUME';
    if (item.category == ItemCategory.miscellaneous) actionLabel = 'USE';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151310),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF3A2C20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.name.toUpperCase(),
                  style: VitruvianTypography.serifTitle(
                    fontSize: 18,
                    color: const Color(0xFFE0C8B0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.weight.toStringAsFixed(2)} KG | ${item.category.name.toUpperCase()}',
                  style: VitruvianTypography.monospaceData(
                    fontSize: 11,
                    color: const Color(0xFF8A7A68),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.description,
                  style: VitruvianTypography.serifBody(
                    fontSize: 14,
                    color: VitruvianColors.agedBone,
                  ),
                ),
                if (item.perks.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'WEAPON PERKS',
                    style: VitruvianTypography.serifTitle(
                      fontSize: 13,
                      color: const Color(0xFFC89B5D),
                    ).copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  ...item.perks.map((perkId) {
                    final perk = WeaponPerkDictionary.getPerk(perkId);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF201B15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF3A2C20)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(perk.icon, size: 20, color: const Color(0xFFC89B5D)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  perk.name.toUpperCase(),
                                  style: VitruvianTypography.serifTitle(
                                    fontSize: 13,
                                    color: const Color(0xFFE0C8B0),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  perk.mechanics,
                                  style: VitruvianTypography.monospaceData(
                                    fontSize: 11,
                                    color: const Color(0xFF9A8A7A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A2C20),
                          foregroundColor: const Color(0xFFC89B5D),
                          side: const BorderSide(color: Color(0xFFC89B5D)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (actionLabel == 'ARM' || actionLabel == 'WEAR') {
                            playerState.equipArtifact(item);
                            Get.snackbar('Inventory', 'Equipped ${item.name}',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: const Color(0xFF201B15),
                                colorText: const Color(0xFFC89B5D));
                          } else {
                            if (item.count <= 1) {
                              inv.removeItem(item.id);
                            }
                            Get.snackbar('Inventory', '$actionLabel ${item.name}',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: const Color(0xFF201B15),
                                colorText: const Color(0xFFC89B5D));
                          }
                        },
                        child: Text(actionLabel, style: VitruvianTypography.serifTitle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          inv.removeItem(item.id);
                          Get.snackbar('Inventory', 'Disposed of ${item.name}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: const Color(0xFF201B15),
                              colorText: Colors.redAccent);
                        },
                        child: Text('DISPOSE', style: VitruvianTypography.serifTitle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
