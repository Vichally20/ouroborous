import 'item.dart';

/// Real item definitions for story loot, looked up by the name used in a chapter's
/// `lootCallout`. Loot not listed here still arrives, as a miscellaneous relic.
class ItemCatalog {
  static const Map<String, ArtifactItem> byName = {
    'rusted falchion': ArtifactItem(
      id: 'w_rusted_falchion',
      name: 'Rusted Falchion',
      description: 'A notched single-edged blade, still keen enough to open a vein.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.common,
      weight: 2.60,
      equipSlot: AnatomicalSlot.mainHand,
      statBonus: 14,
      perks: ['bleed'],
    ),
    'jagged ritual dagger': ArtifactItem(
      id: 'w_ritual_dagger',
      name: 'Jagged Ritual Dagger',
      description: 'A cultist\'s off-hand blade, serrated for blood-letting.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.unpolished,
      weight: 0.90,
      equipSlot: AnatomicalSlot.secondaryHand,
      statBonus: 9,
      perks: ['bleed'],
    ),
    'sealed amphitheater letter': ArtifactItem(
      id: 'q_amphitheater_letter',
      name: 'Sealed Amphitheater Letter',
      description: 'Addressed to the Anatomist-General, Third Chair. The wax bears an ouroboros.',
      category: ItemCategory.miscellaneous,
      rarity: ItemRarity.relic,
      weight: 0.05,
    ),
    'crypt tunnel map': ArtifactItem(
      id: 'q_crypt_map',
      name: 'Crypt Tunnel Map',
      description: 'A hand-inked chart of the passages beneath the Undercroft.',
      category: ItemCategory.miscellaneous,
      rarity: ItemRarity.clinical,
      weight: 0.05,
    ),
    'lunar medallion': ArtifactItem(
      id: 'q_lunar_medallion',
      name: 'Lunar Medallion',
      description: 'Tarnished silver, embossed with a wolf skull. It was around the Alpha\'s throat.',
      category: ItemCategory.miscellaneous,
      rarity: ItemRarity.relic,
      weight: 0.30,
    ),
    'the pulsing vessel': ArtifactItem(
      id: 'q_pulsing_vessel',
      name: 'The Pulsing Vessel',
      description: 'A glass vessel holding a heart that still beats. Warm to the touch.',
      category: ItemCategory.miscellaneous,
      rarity: ItemRarity.vitruvian,
      weight: 1.50,
    ),
    'crimson phylactery': ArtifactItem(
      id: 'q_crimson_phylactery',
      name: 'Crimson Phylactery',
      description: 'A sealed reliquary of the Ouroboros cult, humming faintly.',
      category: ItemCategory.miscellaneous,
      rarity: ItemRarity.relic,
      weight: 0.80,
    ),
  };

  /// Turns a loot callout such as "Acquired: Sealed Amphitheater Letter + Crypt Tunnel Map"
  /// into the items it names.
  static List<ArtifactItem> fromLootCallout(String callout, {required String fallbackIdPrefix}) {
    final text = callout.replaceAll('Loot Uncovered:', '').replaceAll('Acquired:', '').trim();
    final items = <ArtifactItem>[];
    for (final part in text.split('+')) {
      final name = part.replaceAll(RegExp(r'\(.*?\)'), '').trim();
      if (name.isEmpty) continue;
      final known = byName[name.toLowerCase()];
      items.add(known ??
          ArtifactItem(
            id: '${fallbackIdPrefix}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
            name: name,
            description: 'Acquired during the chronicle exploration.',
            category: ItemCategory.miscellaneous,
            rarity: ItemRarity.relic,
            weight: 1.0,
          ));
    }
    return items;
  }
}
