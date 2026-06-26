import 'package:flutter/foundation.dart';
import '../models/item.dart';

class InventoryState extends ChangeNotifier {
  ItemCategory selectedTab = ItemCategory.weapon;

  final List<ArtifactItem> _ledger = [
    const ArtifactItem(
      id: 'w1',
      name: 'Etched Scalpel',
      description: 'Clinical blade razor-sharpened for vascular incision.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.clinical,
      weight: 1.5,
      equipSlot: AnatomicalSlot.mainHand,
      statBonus: 4,
    ),
    const ArtifactItem(
      id: 'a1',
      name: 'Scribe Vellum Apron',
      description: 'Reinforced parchment apron stained with dried umber ink.',
      category: ItemCategory.apparel,
      rarity: ItemRarity.unpolished,
      weight: 4.0,
      equipSlot: AnatomicalSlot.chest,
      statBonus: 2,
    ),
    const ArtifactItem(
      id: 'c1',
      name: 'Laudanum Phial',
      description: 'Bitter botanical distillate that restores 30 Sanity.',
      category: ItemCategory.consumable,
      rarity: ItemRarity.common,
      weight: 0.5,
    ),
  ];

  List<ArtifactItem> get items => _ledger;

  List<ArtifactItem> get filteredItems =>
      _ledger.where((item) => item.category == selectedTab).toList();

  double get totalInventoryWeight =>
      _ledger.fold(0.0, (sum, item) => sum + item.weight);

  void selectTab(ItemCategory category) {
    selectedTab = category;
    notifyListeners();
  }

  void addItem(ArtifactItem item) {
    _ledger.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _ledger.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
