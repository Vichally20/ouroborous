import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/item.dart';
import '../../states/inventory_state.dart';
import '../../states/player_state.dart';
import '../widgets/etched_container.dart';

class InventoryScreen extends StatelessWidget {
  final InventoryState inventoryState;
  final PlayerState playerState;

  const InventoryScreen({
    super.key,
    required this.inventoryState,
    required this.playerState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: inventoryState,
      builder: (context, child) {
        final filtered = inventoryState.filteredItems;

        return Column(
          children: [
            // Categorized Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF0F0E0C),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabBtn('WEAPONS', ItemCategory.weapon),
                  _buildTabBtn('APPAREL', ItemCategory.apparel),
                  _buildTabBtn('CONSUMABLES', ItemCategory.consumable),
                ],
              ),
            ),
            const Divider(),

            // Dense scrollable ledger of artifacts
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No artifacts recorded in this ledger tab.',
                        style: VitruvianTypography.serifBody(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildArtifactTile(item);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBtn(String title, ItemCategory cat) {
    final isSelected = inventoryState.selectedTab == cat;
    return InkWell(
      onTap: () => inventoryState.selectTab(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? VitruvianColors.sepiaUmber : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          title,
          style: VitruvianTypography.monospaceData(
            fontSize: 12,
            color: isSelected ? VitruvianColors.agedBone : Colors.white30,
          ),
        ),
      ),
    );
  }

  Widget _buildArtifactTile(ArtifactItem item) {
    Color rarityColor = Colors.grey;
    switch (item.rarity) {
      case ItemRarity.clinical:
        rarityColor = Colors.cyanAccent;
        break;
      case ItemRarity.relic:
        rarityColor = Colors.amberAccent;
        break;
      case ItemRarity.vitruvian:
        rarityColor = VitruvianColors.sepiaUmber;
        break;
      case ItemRarity.unpolished:
        rarityColor = Colors.white70;
        break;
      case ItemRarity.common:
        rarityColor = Colors.grey;
        break;
    }

    return EtchedContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            color: rarityColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.name, style: VitruvianTypography.serifTitle(fontSize: 16)),
                    Text('${item.weight} KG', style: VitruvianTypography.monospaceData(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: VitruvianTypography.serifBody(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RARITY: ${item.rarity.name.toUpperCase()}',
                      style: VitruvianTypography.monospaceData(fontSize: 10, color: rarityColor),
                    ),
                    if (item.equipSlot != AnatomicalSlot.none)
                      InkWell(
                        onTap: () => playerState.equipArtifact(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: VitruvianColors.sepiaUmber),
                          ),
                          child: Text('EQUIP TO ${item.equipSlot.name.toUpperCase()}',
                              style: VitruvianTypography.monospaceData(fontSize: 9)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
