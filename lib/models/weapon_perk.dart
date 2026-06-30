import 'package:flutter/material.dart';

class WeaponPerk {
  final String id;
  final String name;
  final String description;
  final String mechanics;
  final IconData icon;

  const WeaponPerk({
    required this.id,
    required this.name,
    required this.description,
    required this.mechanics,
    this.icon = Icons.star,
  });
}

class WeaponPerkDictionary {
  static final Map<String, WeaponPerk> _perks = {
    'parry': const WeaponPerk(
      id: 'parry',
      name: 'Parry',
      description: 'Redirects incoming melee strikes to negate damage.',
      mechanics: 'Successful execution negates damage and creates a counterattack window.',
      icon: Icons.shield_outlined,
    ),
    'bleed': const WeaponPerk(
      id: 'bleed',
      name: 'Bleed',
      description: 'Inflicts deep wounds that cause physical damage over time.',
      mechanics: 'Deals physical damage over time (DoT) at the end of each turn, stacking up to 5 times.',
      icon: Icons.water_drop,
    ),
    'execute': const WeaponPerk(
      id: 'execute',
      name: 'Execute',
      description: 'Lethal finishing strike against weakened targets.',
      mechanics: 'Deals x3.0 multiplier damage to targets under 30% health or with active bleed/stun.',
      icon: Icons.flash_on,
    ),
    'lock_on': const WeaponPerk(
      id: 'lock_on',
      name: 'Lock-On',
      description: 'Focuses anatomical precision on a single target.',
      mechanics: 'Focuses all subsequent attacks on a specific anatomical part, increasing critical chance.',
      icon: Icons.gps_fixed,
    ),
    'expose_weakness': const WeaponPerk(
      id: 'expose_weakness',
      name: 'Expose Weakness',
      description: 'Vibrates high-frequency cuts through gaps in armor.',
      mechanics: 'Reduces enemy physical armor by 25% for 2 turns.',
      icon: Icons.broken_image,
    ),
  };

  static WeaponPerk getPerk(String id) {
    return _perks[id] ??
        WeaponPerk(
          id: id,
          name: _formatName(id),
          description: 'Weapon special property.',
          mechanics: 'Passive enchantment.',
          icon: Icons.auto_awesome,
        );
  }

  static String _formatName(String id) {
    return id
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  static List<WeaponPerk> get allPerks => _perks.values.toList();
}
