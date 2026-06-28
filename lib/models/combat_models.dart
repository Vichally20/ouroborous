import 'package:get/get.dart';

class AiProfile {
  final double aggression; // 1.0 = Attacks constantly, 0.1 = Rarely attacks
  final double selfPreservation; // 1.0 = Runs/Defends at low HP, 0.1 = Fights to the death
  final double preferredRange; // 0 = Melee lane, 2 = Far lane

  const AiProfile({
    required this.aggression,
    required this.selfPreservation,
    required this.preferredRange,
  });

  factory AiProfile.fromJson(Map<String, dynamic> json) {
    return AiProfile(
      aggression: (json['aggression'] as num?)?.toDouble() ?? 0.5,
      selfPreservation: (json['self_preservation'] as num?)?.toDouble() ?? 0.5,
      preferredRange: (json['preferred_range'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

abstract class CombatEntity {
  final String id;
  final String name;
  final String imageAsset;
  final int maxHp;
  final int maxStamina;
  final int strength;
  final int defense;
  final int speed;

  // Reactive state
  final RxInt hp;
  final RxInt stamina;
  final RxString lane; // 'front' or 'back'
  final RxBool isDead;

  CombatEntity({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.maxHp,
    required this.maxStamina,
    required this.strength,
    required this.defense,
    required this.speed,
    required int initialHp,
    required int initialStamina,
    required String initialLane,
  })  : hp = initialHp.obs,
        stamina = initialStamina.obs,
        lane = initialLane.obs,
        isDead = (initialHp <= 0).obs;
}

class Enemy extends CombatEntity {
  final AiProfile aiProfile;
  final List<String> availableSkills;

  Enemy({
    required super.id,
    required super.name,
    required super.imageAsset,
    required super.maxHp,
    required super.maxStamina,
    required super.strength,
    required super.defense,
    required super.speed,
    required super.initialHp,
    required super.initialStamina,
    required super.initialLane,
    required this.aiProfile,
    required this.availableSkills,
  });

  factory Enemy.fromJson(String id, Map<String, dynamic> json, String initialLane) {
    final stats = json['stats'] as Map<String, dynamic>;
    
    // Check if maxHealth is provided, else fallback to maxHp
    final int maxHealth = stats['maxHealth'] ?? stats['maxHp'] ?? 50;
    final int maxStam = stats['maxStamina'] ?? 50;

    return Enemy(
      id: id,
      name: json['name'] as String,
      imageAsset: json['imageAsset'] as String? ?? 'assets/images/enemy_werewolf_black.png',
      maxHp: maxHealth,
      maxStamina: maxStam,
      strength: stats['strength'] ?? 10,
      defense: stats['defense'] ?? 5,
      speed: stats['speed'] ?? 10,
      initialHp: maxHealth,
      initialStamina: maxStam,
      initialLane: initialLane,
      aiProfile: AiProfile.fromJson(json['ai_profile'] as Map<String, dynamic>),
      availableSkills: List<String>.from(json['skills'] as List? ?? []),
    );
  }

  // Helper to clone an enemy with a unique instance ID for combat
  Enemy clone(String instanceId, String startingLane) {
    return Enemy(
      id: instanceId,
      name: name,
      imageAsset: imageAsset,
      maxHp: maxHp,
      maxStamina: maxStamina,
      strength: strength,
      defense: defense,
      speed: speed,
      initialHp: maxHp,
      initialStamina: maxStamina,
      initialLane: startingLane,
      aiProfile: aiProfile,
      availableSkills: availableSkills,
    );
  }
}
