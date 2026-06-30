import 'package:flutter/material.dart';

enum SkillType { physical, magical, tactical }
enum SkillTarget { singleEnemy, allEnemies, self, allAllies }

class CombatSkill {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int apCost;
  final int staminaCost;
  final SkillType type;
  final SkillTarget target;
  final int minDamage;
  final int maxDamage;
  final double frontLineMultiplier;
  final double backLineMultiplier;
  final bool ignoresArmor;
  final int healAmount;
  final int staminaRestore;
  final String effectDescription;

  const CombatSkill({
    required this.id,
    required this.name,
    required this.description,
    this.icon = Icons.adjust,
    this.apCost = 1,
    this.staminaCost = 15,
    this.type = SkillType.physical,
    this.target = SkillTarget.singleEnemy,
    this.minDamage = 10,
    this.maxDamage = 15,
    this.frontLineMultiplier = 1.0,
    this.backLineMultiplier = 1.0,
    this.ignoresArmor = false,
    this.healAmount = 0,
    this.staminaRestore = 0,
    this.effectDescription = '',
  });
}

class SkillDictionary {
  static final Map<String, CombatSkill> _skills = {
    // ─── PLAYER SKILLS ───
    'blood_falchion_strike': const CombatSkill(
      id: 'blood_falchion_strike',
      name: 'Blood Falchion Strike',
      description: 'Inflicts physical damage. Deals +50% damage from Front Line, -30% from Back Line.',
      icon: Icons.flash_on,
      apCost: 1,
      staminaCost: 20,
      type: SkillType.physical,
      minDamage: 15,
      maxDamage: 22,
      frontLineMultiplier: 1.5,
      backLineMultiplier: 0.7,
      effectDescription: '+4 Bleed',
    ),
    'hermetic_firebolt': const CombatSkill(
      id: 'hermetic_firebolt',
      name: 'Hermetic Firebolt',
      description: 'Launches alchemical plasma dealing magical fire damage. Fully effective from any lane.',
      icon: Icons.local_fire_department,
      apCost: 1,
      staminaCost: 40,
      type: SkillType.magical,
      minDamage: 25,
      maxDamage: 35,
      effectDescription: 'Burn Effect',
    ),
    'shield_brace': const CombatSkill(
      id: 'shield_brace',
      name: 'Shield Brace',
      description: 'Raise your shield, cutting incoming damage by 50% and restoring stamina.',
      icon: Icons.shield,
      apCost: 1,
      staminaCost: 0,
      type: SkillType.tactical,
      target: SkillTarget.self,
      minDamage: 0,
      maxDamage: 0,
      staminaRestore: 30,
      effectDescription: '+50% Defense',
    ),

    // ─── ENEMY SKILLS ───
    'bite': const CombatSkill(
      id: 'bite',
      name: 'Savage Bite',
      description: 'A vicious bite aiming for arteries.',
      icon: Icons.pets,
      apCost: 1,
      staminaCost: 15,
      type: SkillType.physical,
      minDamage: 12,
      maxDamage: 18,
      frontLineMultiplier: 1.2,
      effectDescription: '+3 Bleed',
    ),
    'lunge': const CombatSkill(
      id: 'lunge',
      name: 'Feral Lunge',
      description: 'Leaps rapidly across the battlefield to strike.',
      icon: Icons.directions_run,
      apCost: 1,
      staminaCost: 20,
      type: SkillType.physical,
      minDamage: 14,
      maxDamage: 20,
      effectDescription: 'Gap Closer',
    ),
    'shadow_swipe': const CombatSkill(
      id: 'shadow_swipe',
      name: 'Shadow Swipe',
      description: 'Dark claws slash out from unseen angles.',
      icon: Icons.nightlight_round,
      apCost: 1,
      staminaCost: 25,
      type: SkillType.physical,
      minDamage: 15,
      maxDamage: 24,
      ignoresArmor: true,
      effectDescription: 'Ignores Defense',
    ),
    'retreat': const CombatSkill(
      id: 'retreat',
      name: 'Shadow Retreat',
      description: 'Melts into the shadows and shifts back.',
      icon: Icons.arrow_back,
      apCost: 1,
      staminaCost: 10,
      type: SkillType.tactical,
      target: SkillTarget.self,
      minDamage: 0,
      maxDamage: 0,
      effectDescription: 'Evasion + Back Line',
    ),
    'alpha_howl': const CombatSkill(
      id: 'alpha_howl',
      name: 'Alpha Howl',
      description: 'A terrifying blood-curdling roar that shakes resolve.',
      icon: Icons.volume_up,
      apCost: 1,
      staminaCost: 30,
      type: SkillType.tactical,
      target: SkillTarget.allAllies,
      minDamage: 0,
      maxDamage: 0,
      effectDescription: '+20% Pack Attack',
    ),
    'heavy_slash': const CombatSkill(
      id: 'heavy_slash',
      name: 'Heavy Slash',
      description: 'A brutal two-claw overhead swing.',
      icon: Icons.gavel,
      apCost: 1,
      staminaCost: 35,
      type: SkillType.physical,
      minDamage: 20,
      maxDamage: 30,
      frontLineMultiplier: 1.3,
      effectDescription: 'High Knockback',
    ),
    'blood_hex': const CombatSkill(
      id: 'blood_hex',
      name: 'Blood Hex',
      description: 'Occult blood magic that siphons vitality.',
      icon: Icons.bloodtype,
      apCost: 1,
      staminaCost: 25,
      type: SkillType.magical,
      minDamage: 16,
      maxDamage: 22,
      healAmount: 10,
      effectDescription: 'Life Drain (+10 HP)',
    ),
    'crushing_blow': const CombatSkill(
      id: 'crushing_blow',
      name: 'Crushing Blow',
      description: 'A colossal mechanical slam that pulverizes armor.',
      icon: Icons.hardware,
      apCost: 2,
      staminaCost: 40,
      type: SkillType.physical,
      minDamage: 28,
      maxDamage: 45,
      ignoresArmor: true,
      effectDescription: 'Shatters Armor & Stuns',
    ),
  };

  static CombatSkill getSkill(String id) {
    return _skills[id] ??
        CombatSkill(
          id: id,
          name: _formatName(id),
          description: 'Standard combat ability.',
          icon: Icons.adjust,
        );
  }

  static String _formatName(String id) {
    return id
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  static List<CombatSkill> get allSkills => _skills.values.toList();
}
