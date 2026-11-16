import 'package:get/get.dart';
import '../models/item.dart';

class InventoryState extends GetxController {
  final selectedTab = ItemCategory.weapon.obs;

  final ledger = <ArtifactItem>[
    // Currency
    const ArtifactItem(
      id: 'cur1',
      name: 'Ouroboros Crowns',
      description: 'Ancient royal coinage bearing the serpent seal.',
      category: ItemCategory.currency,
      rarity: ItemRarity.relic,
      weight: 0.0,
      count: 2450,
    ),
    const ArtifactItem(
      id: 'cur2',
      name: 'Ancient Drachma',
      description: 'Silver obols recovered from hermetic catacombs.',
      category: ItemCategory.currency,
      rarity: ItemRarity.common,
      weight: 0.0,
      count: 145,
    ),

    // Weapons: the heroes start holding the Claymore, Cinquedea and Shortbow (see PlayerState).

    // Apparel
    const ArtifactItem(
      id: 'ap2',
      name: 'Vanguard Greaves',
      description: 'Thick bronze leg-plates designed to absorb cavalry charges.',
      category: ItemCategory.apparel,
      rarity: ItemRarity.clinical,
      weight: 12.40,
      equipSlot: AnatomicalSlot.leg,
      statBonus: 22,
      count: 1,
    ),
    const ArtifactItem(
      id: 'ap3',
      name: 'Linen Hand-wraps',
      description: 'Sanitized bandages that prevent blistering and grip slippage.',
      category: ItemCategory.apparel,
      rarity: ItemRarity.common,
      weight: 0.10,
      equipSlot: AnatomicalSlot.secondaryHand,
      statBonus: 4,
      count: 1,
    ),

    // Consumables
    const ArtifactItem(
      id: 'c1',
      name: 'Essence of Clarity',
      description: 'Distilled alchemical vapor that instantly purges mental fog.',
      category: ItemCategory.consumable,
      rarity: ItemRarity.clinical,
      weight: 0.80,
      count: 4,
    ),
    const ArtifactItem(
      id: 'c2',
      name: 'Blood-Stained Parchment',
      description: 'Forbidden anatomical notes that grant temporary occult insight.',
      category: ItemCategory.consumable,
      rarity: ItemRarity.unpolished,
      weight: 0.05,
      count: 12,
    ),
    const ArtifactItem(
      id: 'c3',
      name: 'Mandrake Root (Dried)',
      description: 'Pungent root fiber used to synthesize potent coagulants.',
      category: ItemCategory.consumable,
      rarity: ItemRarity.common,
      weight: 0.40,
      count: 2,
    ),
    const ArtifactItem(
      id: 'c4',
      name: 'Corrupted Soul Gem',
      description: 'Crystalline vessel throbbing with trapped necrotic energy.',
      category: ItemCategory.consumable,
      rarity: ItemRarity.relic,
      weight: 1.00,
      count: 1,
    ),

    // Miscellaneous
    const ArtifactItem(
      id: 'm1',
      name: 'Rusty Vault Key',
      description: 'Heavy iron skeleton key encrusted with green patina.',
      category: ItemCategory.miscellaneous,
      rarity: ItemRarity.common,
      weight: 0.05,
      count: 1,
    ),
    const ArtifactItem(
      id: 'm2',
      name: 'Hermetic Astrolabe',
      description: 'Brass navigational device calibrated for subterranean stars.',
      category: ItemCategory.miscellaneous,
      rarity: ItemRarity.relic,
      weight: 1.50,
      count: 1,
    ),
  ].obs;

  List<ArtifactItem> get items => ledger;

  List<ArtifactItem> get filteredItems =>
      ledger.where((item) => item.category == selectedTab.value).toList();

  /// Carried weight: every item in a stack counts.
  double get totalInventoryWeight =>
      ledger.fold(0.0, (sum, item) => sum + item.weight * item.count);

  int countOf(String id) => ledger.firstWhereOrNull((i) => i.id == id)?.count ?? 0;

  void selectTab(ItemCategory category) {
    selectedTab.value = category;
  }

  /// Adds [count] of [item], merging into an existing stack with the same id.
  void addItem(ArtifactItem item, {int? count}) {
    final n = count ?? item.count;
    if (n <= 0) return;
    final i = ledger.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      ledger[i] = ledger[i].copyWith(count: ledger[i].count + n);
    } else {
      ledger.add(item.copyWith(count: n));
    }
  }

  /// Removes [count] from the stack with [id] (default one item). Returns false if
  /// there weren't enough. The stack disappears when it reaches zero.
  bool removeItem(String id, {int count = 1}) {
    final i = ledger.indexWhere((e) => e.id == id);
    if (i < 0 || ledger[i].count < count) return false;
    final left = ledger[i].count - count;
    if (left <= 0) {
      ledger.removeAt(i);
    } else {
      ledger[i] = ledger[i].copyWith(count: left);
    }
    return true;
  }

  /// Removes the whole stack with [id].
  void removeStack(String id) {
    ledger.removeWhere((item) => item.id == id);
  }
}
