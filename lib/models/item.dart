enum ItemCategory { weapon, apparel, consumable, essence, miscellaneous, currency }

enum ItemRarity { common, unpolished, clinical, relic, vitruvian }

enum AnatomicalSlot { head, chest, leg, mainHand, secondaryHand, none }

enum WeaponRange { melee, ranged }

class ArtifactItem {
  final String id;
  final String name;
  final String description;
  final ItemCategory category;
  final ItemRarity rarity;
  final double weight;
  final AnatomicalSlot equipSlot;
  final int statBonus;
  final int count;
  final WeaponRange weaponRange;
  final List<String> perks;

  const ArtifactItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.weight,
    this.equipSlot = AnatomicalSlot.none,
    this.statBonus = 0,
    this.count = 1,
    this.weaponRange = WeaponRange.melee,
    this.perks = const [],
    this.twoHanded = false,
    this.temper = 0,
  });

  /// Forge upgrades (0-[maxTemper]). Adds [temperBonus] to the item's power.
  final int temper;
  static const maxTemper = 3;
  static const _weaponTemper = [0, 3, 7, 12];
  static const _apparelTemper = [0, 2, 5, 9];

  /// Extra damage (weapons) or armour (apparel) from tempering.
  int get temperBonus {
    final t = temper.clamp(0, maxTemper);
    if (category == ItemCategory.weapon) return _weaponTemper[t];
    if (category == ItemCategory.apparel) return _apparelTemper[t];
    return 0;
  }

  /// What the item brings to battle: base bonus plus tempering.
  int get power => statBonus + temperBonus;

  /// Name with its temper, e.g. "Blackiron Claymore +2".
  String get displayName => temper > 0 ? '$name +$temper' : name;

  /// The id without any temper suffix, so tempered copies trace back to their base item.
  String get baseId => id.split('@t').first;

  /// A two-handed main-hand weapon also occupies the secondary hand.
  final bool twoHanded;

  bool get isEquippable => equipSlot != AnatomicalSlot.none;

  ArtifactItem copyWith({int? count, int? temper, String? id}) => ArtifactItem(
        id: id ?? this.id,
        name: name,
        description: description,
        category: category,
        rarity: rarity,
        weight: weight,
        equipSlot: equipSlot,
        statBonus: statBonus,
        count: count ?? this.count,
        weaponRange: weaponRange,
        perks: perks,
        twoHanded: twoHanded,
        temper: temper ?? this.temper,
      );

  /// Full item record for save files, so loot and tempered copies survive a reload.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'rarity': rarity.name,
        'weight': weight,
        'equipSlot': equipSlot.name,
        'statBonus': statBonus,
        'count': count,
        'weaponRange': weaponRange.name,
        'perks': perks,
        'twoHanded': twoHanded,
        'temper': temper,
      };

  factory ArtifactItem.fromJson(Map<String, dynamic> j) => ArtifactItem(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        category: ItemCategory.values.byName(j['category'] as String),
        rarity: ItemRarity.values.byName(j['rarity'] as String),
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
        equipSlot: AnatomicalSlot.values.byName(j['equipSlot'] as String? ?? 'none'),
        statBonus: j['statBonus'] as int? ?? 0,
        count: j['count'] as int? ?? 1,
        weaponRange: WeaponRange.values.byName(j['weaponRange'] as String? ?? 'melee'),
        perks: [...(j['perks'] as List? ?? const []).cast<String>()],
        twoHanded: j['twoHanded'] as bool? ?? false,
        temper: j['temper'] as int? ?? 0,
      );
}
