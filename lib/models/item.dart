enum ItemCategory { weapon, apparel, consumable, essence }

enum ItemRarity { common, unpolished, clinical, relic, vitruvian }

enum AnatomicalSlot { head, chest, leg, mainHand, secondaryHand, none }

class ArtifactItem {
  final String id;
  final String name;
  final String description;
  final ItemCategory category;
  final ItemRarity rarity;
  final double weight;
  final AnatomicalSlot equipSlot;
  final int statBonus;

  const ArtifactItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.weight,
    this.equipSlot = AnatomicalSlot.none,
    this.statBonus = 0,
  });
}
