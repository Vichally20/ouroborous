import 'package:flutter/material.dart';

import 'character_class.dart';

/// What a talent changes in battle. Every field defaults to "no effect" so a
/// node only states the numbers it actually changes.
class TalentEffect {
  /// Strength multiplier bonus, e.g. 0.10 = +10% Strength.
  final double strengthPct;

  /// Flat armour added to the hero's defense.
  final int defenseFlat;

  /// Speed multiplier bonus (negative slows the hero).
  final double speedPct;

  /// Outgoing damage multiplier bonus, e.g. 0.15 = +15% damage dealt.
  final double damageDealtPct;

  /// Incoming damage multiplier change, e.g. -0.15 = take 15% less, 0.05 = take 5% more.
  final double damageTakenPct;

  /// Added to critical-hit chance, in percentage points.
  final int critChance;

  /// Added to the chance that an enemy's hit only glances, in percentage points.
  final int evasion;

  /// Extra damage with a two-handed main-hand weapon, e.g. 0.25 = +25%.
  final double twoHandedDamagePct;

  /// Extra damage reduction while defending, e.g. 0.10 turns a 50% guard into 60%.
  final double guardBonus;

  /// Stamina restored each time an attack lands on you while you defend.
  final int staminaOnBlock;

  /// When hit while defending, strike back for this fraction of your basic hit (ignores armour).
  final double counterOnBlock;

  /// Bleed stacks added when you land a critical hit.
  final int bleedOnCrit;

  /// Fraction of the target's armour your attacks ignore, e.g. 0.25.
  final double armorIgnore;

  /// Damage multiplier against bleeding targets below 30% HP (1.0 = no effect).
  final double executeMultiplier;

  const TalentEffect({
    this.strengthPct = 0,
    this.defenseFlat = 0,
    this.speedPct = 0,
    this.damageDealtPct = 0,
    this.damageTakenPct = 0,
    this.critChance = 0,
    this.evasion = 0,
    this.twoHandedDamagePct = 0,
    this.guardBonus = 0,
    this.staminaOnBlock = 0,
    this.counterOnBlock = 0,
    this.bleedOnCrit = 0,
    this.armorIgnore = 0,
    this.executeMultiplier = 1.0,
  });

  static const none = TalentEffect();

  TalentEffect operator +(TalentEffect o) => TalentEffect(
        strengthPct: strengthPct + o.strengthPct,
        defenseFlat: defenseFlat + o.defenseFlat,
        speedPct: speedPct + o.speedPct,
        damageDealtPct: damageDealtPct + o.damageDealtPct,
        damageTakenPct: damageTakenPct + o.damageTakenPct,
        critChance: critChance + o.critChance,
        evasion: evasion + o.evasion,
        twoHandedDamagePct: twoHandedDamagePct + o.twoHandedDamagePct,
        guardBonus: guardBonus + o.guardBonus,
        staminaOnBlock: staminaOnBlock + o.staminaOnBlock,
        counterOnBlock: counterOnBlock + o.counterOnBlock,
        bleedOnCrit: bleedOnCrit + o.bleedOnCrit,
        armorIgnore: (armorIgnore + o.armorIgnore).clamp(0.0, 1.0),
        // Execute effects don't stack additively; the strongest one applies.
        executeMultiplier: executeMultiplier > o.executeMultiplier ? executeMultiplier : o.executeMultiplier,
      );
}

/// A line shown on the talent card. Text only; [TalentEffect] holds the real numbers.
class NodeBonus {
  final String label;
  final String value;
  const NodeBonus(this.label, this.value);
}

class TalentNode {
  final String id;
  final String title;
  final String rank;
  final String lore;
  final List<NodeBonus> bonuses;
  final TalentEffect effect;

  /// Position on the 340×420 constellation canvas.
  final Offset pos;

  /// Nodes directly above this one. Owning ANY of them makes this node reachable,
  /// so progress always flows downward from the root.
  final List<String> parentIds;

  /// Fallback glyph, shown only if [iconAsset] is missing.
  final IconData icon;

  /// Engraved medallion (transparent PNG), clipped round by the talent screen.
  final String? iconAsset;

  const TalentNode({
    required this.id,
    required this.title,
    required this.rank,
    required this.lore,
    required this.bonuses,
    required this.effect,
    required this.pos,
    required this.icon,
    this.iconAsset,
    this.parentIds = const [],
  });

  bool get isRoot => parentIds.isEmpty;
}

class TalentTree {
  final String id;
  final List<TalentNode> nodes;
  const TalentTree({required this.id, required this.nodes});

  TalentNode? node(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  String get rootId => nodes.firstWhere((n) => n.isRoot).id;

  /// Sum of the effects of every unlocked node in this tree.
  TalentEffect effectOf(Iterable<String> unlocked) {
    var total = TalentEffect.none;
    for (final id in unlocked) {
      final n = node(id);
      if (n != null) total = total + n.effect;
    }
    return total;
  }

  /// A node can be taken when it isn't owned yet and at least one parent is owned.
  /// Owned nodes are permanent, so the tree can only be walked downward.
  bool isReachable(String id, Set<String> unlocked) {
    final n = node(id);
    if (n == null || unlocked.contains(id)) return false;
    if (n.isRoot) return true;
    return n.parentIds.any(unlocked.contains);
  }

  static TalentTree? forClass(PersonalityClassType type) {
    switch (type) {
      case PersonalityClassType.warrior:
        return warrior;
      case PersonalityClassType.sorcerer:
      case PersonalityClassType.assassin:
        return null; // Not charted yet.
    }
  }

  static const warrior = TalentTree(id: 'warrior', nodes: [
    // TIER I
    TalentNode(
      id: 'root',
      title: 'Iron Fundamentals',
      rank: 'TIER I : ROOT',
      lore: 'Drilled stance and hardened bone: the base every Vanguard builds on.',
      bonuses: [NodeBonus('Strength', '+10%'), NodeBonus('Armour', '+2')],
      effect: TalentEffect(strengthPct: 0.10, defenseFlat: 2),
      pos: Offset(170, 45),
      icon: Icons.shield,
      iconAsset: 'assets/images/talents/talent_iron_fundamentals.png',
    ),
    // TIER II
    TalentNode(
      id: 'branchA',
      title: 'Juggernaut',
      rank: 'TIER II : BRANCH A',
      lore: 'An immovable bulwark of martial iron.',
      bonuses: [NodeBonus('Damage Taken', '-15%'), NodeBonus('Speed', '-5%')],
      effect: TalentEffect(damageTakenPct: -0.15, speedPct: -0.05),
      parentIds: ['root'],
      pos: Offset(55, 145),
      icon: Icons.security,
      iconAsset: 'assets/images/talents/talent_juggernaut.png',
    ),
    TalentNode(
      id: 'branchB',
      title: 'Berserker',
      rank: 'TIER II : BRANCH B',
      lore: 'Unrelenting fury born of sacrificial bloodshed.',
      bonuses: [NodeBonus('Damage Dealt', '+15%'), NodeBonus('Damage Taken', '+5%')],
      effect: TalentEffect(damageDealtPct: 0.15, damageTakenPct: 0.05),
      parentIds: ['root'],
      pos: Offset(170, 145),
      icon: Icons.local_fire_department,
      iconAsset: 'assets/images/talents/talent_berserker.png',
    ),
    TalentNode(
      id: 'branchC',
      title: 'Duelist',
      rank: 'TIER II : BRANCH C',
      lore: 'Footwork and reach: the long blade in a trained grip.',
      bonuses: [
        NodeBonus('Critical Chance', '+10%'),
        NodeBonus('Evasion', '+10%'),
        NodeBonus('Two-Handed Damage', '+25%'),
      ],
      effect: TalentEffect(critChance: 10, evasion: 10, twoHandedDamagePct: 0.25),
      parentIds: ['root'],
      pos: Offset(285, 145),
      icon: Icons.sports_martial_arts,
      iconAsset: 'assets/images/talents/talent_duelist.png',
    ),
    // TIER III
    TalentNode(
      id: 'nodeA1',
      title: 'Shield Wall',
      rank: 'TIER III : FROM A',
      lore: 'Every blow you catch feeds the next.',
      bonuses: [NodeBonus('Guard Reduction', '+10%'), NodeBonus('Stamina per Block', '+10')],
      effect: TalentEffect(guardBonus: 0.10, staminaOnBlock: 10),
      parentIds: ['branchA'],
      pos: Offset(35, 255),
      icon: Icons.shield_outlined,
      iconAsset: 'assets/images/talents/talent_shield_wall.png',
    ),
    TalentNode(
      id: 'nodeA2',
      title: 'Vanguard\'s Retribution',
      rank: 'TIER III : FROM A OR B',
      lore: 'A blocked blow is answered with a sweeping counter.',
      bonuses: [NodeBonus('Counter on Block', '50% of a strike'), NodeBonus('Counter', 'Ignores armour')],
      effect: TalentEffect(counterOnBlock: 0.5),
      parentIds: ['branchA', 'branchB'],
      pos: Offset(120, 255),
      icon: Icons.hardware,
      iconAsset: 'assets/images/talents/talent_retribution.png',
    ),
    TalentNode(
      id: 'nodeC1',
      title: 'Flurry of Death',
      rank: 'TIER III : FROM B OR C',
      lore: 'Critical hits open the veins.',
      bonuses: [NodeBonus('Bleed on Critical', '+3 stacks')],
      effect: TalentEffect(bleedOnCrit: 3),
      parentIds: ['branchB', 'branchC'],
      pos: Offset(220, 255),
      icon: Icons.storm,
      iconAsset: 'assets/images/talents/talent_flurry_of_death.png',
    ),
    TalentNode(
      id: 'nodeC2',
      title: 'Expose Weakness',
      rank: 'TIER III : FROM C',
      lore: 'Strikes find the seams in the plate.',
      bonuses: [NodeBonus('Armour Ignored', '25%')],
      effect: TalentEffect(armorIgnore: 0.25),
      parentIds: ['branchC'],
      pos: Offset(305, 255),
      icon: Icons.gps_fixed,
      iconAsset: 'assets/images/talents/talent_expose_weakness.png',
    ),
    // TIER IV
    TalentNode(
      id: 'capstone',
      title: 'Execute',
      rank: 'TIER IV : CAPSTONE',
      lore: 'The final blow on a bleeding, failing foe.',
      bonuses: [NodeBonus('vs Bleeding below 30% HP', 'x3 Damage')],
      effect: TalentEffect(executeMultiplier: 3.0),
      parentIds: ['nodeA2', 'nodeC1'],
      pos: Offset(170, 365),
      icon: Icons.auto_awesome,
      iconAsset: 'assets/images/talents/talent_execute.png',
    ),
  ]);
}
