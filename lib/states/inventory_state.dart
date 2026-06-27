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

    // Weapons
    const ArtifactItem(
      id: 'w1',
      name: 'Blackiron Claymore',
      description: 'Massive greatsword forged from dense meteoric iron.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.relic,
      weight: 8.50,
      equipSlot: AnatomicalSlot.mainHand,
      statBonus: 18,
      count: 1,
    ),
    const ArtifactItem(
      id: 'w2',
      name: 'Cinquedea of the Blind',
      description: 'Broad ceremonial dagger engraved with braille runes.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.clinical,
      weight: 1.25,
      equipSlot: AnatomicalSlot.secondaryHand,
      statBonus: 12,
      count: 1,
    ),
    const ArtifactItem(
      id: 'w3',
      name: 'Weathered Shortbow',
      description: 'Yew recurve bow seasoned by ash and damp air.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.common,
      weight: 2.00,
      equipSlot: AnatomicalSlot.mainHand,
      statBonus: 10,
      count: 1,
    ),

    // Apparel
    const ArtifactItem(
      id: 'ap1',
      name: 'Scholar\'s Tattered Robes',
      description: 'Heavy academic vestments infused with alchemical fumes.',
      category: ItemCategory.apparel,
      rarity: ItemRarity.unpolished,
      weight: 3.20,
      equipSlot: AnatomicalSlot.chest,
      statBonus: 14,
      count: 1,
    ),
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

  double get totalInventoryWeight =>
      ledger.fold(0.0, (sum, item) => sum + item.weight);

  void selectTab(ItemCategory category) {
    selectedTab.value = category;
  }

  void addItem(ArtifactItem item) {
    ledger.add(item);
  }

  void removeItem(String id) {
    ledger.removeWhere((item) => item.id == id);
  }
}
