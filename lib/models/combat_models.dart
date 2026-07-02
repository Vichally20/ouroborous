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

abstract class CombatDefinition {
  String get id;
  String get name;
}

abstract class CombatEntity {
  String get id;
  String get name;
  String get imageAsset;
  int get maxHp;
  int get maxStamina;
  int get strength;
  int get defense;
  int get speed;

  // Reactive state
  RxInt get hp;
  RxInt get stamina;
  RxString get lane; // 'front' or 'back'
  RxBool get isDead;
}

class EnemyTemplate implements CombatDefinition {
  @override
  final String id;
  @override
  final String name;
  final String imageAsset;
  final int maxHp;
  final int maxStamina;
  final int strength;
  final int defense;
  final int speed;
  final AiProfile aiProfile;
  final List<String> availableSkills;

  const EnemyTemplate({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.maxHp,
    required this.maxStamina,
    required this.strength,
    required this.defense,
    required this.speed,
    required this.aiProfile,
    required this.availableSkills,
  });

  factory EnemyTemplate.fromJson(String id, Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;

    // Strictly enforce maxHp from schema without sloppy fallback keys
    final int maxHealth = stats['maxHp'] ?? 50;
    final int maxStam = stats['maxStamina'] ?? 50;

    return EnemyTemplate(
      id: id,
      name: json['name'] as String,
      imageAsset: json['imageAsset'] as String? ?? 'assets/images/enemy_werewolf_black.png',
      maxHp: maxHealth,
      maxStamina: maxStam,
      strength: stats['strength'] ?? 10,
      defense: stats['defense'] ?? 5,
      speed: stats['speed'] ?? 10,
      aiProfile: AiProfile.fromJson(json['ai_profile'] as Map<String, dynamic>),
      availableSkills: List<String>.from(json['skills'] as List? ?? []),
    );
  }
}

class ActiveEnemy implements CombatEntity {
  final String instanceId;
  final EnemyTemplate template;
  final int _overrideMaxHp;
  final int _overrideMaxStamina;
  final int _overrideStrength;
  final int _overrideDefense;
  final String _overrideName;

  @override
  final RxInt hp;
  @override
  final RxInt stamina;
  @override
  final RxString lane;
  @override
  final RxBool isDead;

  ActiveEnemy({
    required this.instanceId,
    required this.template,
    required int initialHp,
    required int initialStamina,
    required String initialLane,
    String? nameOverride,
    int? maxHpOverride,
    int? maxStaminaOverride,
    int? strengthOverride,
    int? defenseOverride,
  })  : _overrideName = nameOverride ?? template.name,
        _overrideMaxHp = maxHpOverride ?? template.maxHp,
        _overrideMaxStamina = maxStaminaOverride ?? template.maxStamina,
        _overrideStrength = strengthOverride ?? template.strength,
        _overrideDefense = defenseOverride ?? template.defense,
        hp = initialHp.obs,
        stamina = initialStamina.obs,
        lane = initialLane.obs,
        isDead = (initialHp <= 0).obs;

  @override
  String get id => instanceId;
  @override
  String get name => _overrideName;
  @override
  String get imageAsset => template.imageAsset;
  @override
  int get maxHp => _overrideMaxHp;
  @override
  int get maxStamina => _overrideMaxStamina;
  @override
  int get strength => _overrideStrength;
  @override
  int get defense => _overrideDefense;
  @override
  int get speed => template.speed;

  AiProfile get aiProfile => template.aiProfile;
  List<String> get availableSkills => template.availableSkills;
}

class ActiveHero implements CombatEntity {
  @override
  final String id;
  @override
  final String name;
  @override
  final String imageAsset;
  @override
  final int maxHp;
  @override
  final int maxStamina;
  @override
  final int strength;
  @override
  final int defense;
  @override
  final int speed;

  @override
  final RxInt hp;
  @override
  final RxInt stamina;
  @override
  final RxString lane;
  @override
  final RxBool isDead;

  ActiveHero({
    required this.id,
    required this.name,
    this.imageAsset = 'assets/images/player.png',
    required this.maxHp,
    required this.maxStamina,
    required this.strength,
    required this.defense,
    required this.speed,
    required RxInt hpObservable,
    required RxInt staminaObservable,
    required RxString laneObservable,
  })  : hp = hpObservable,
        stamina = staminaObservable,
        lane = laneObservable,
        isDead = (hpObservable.value <= 0).obs;
}

class AllyTemplate implements CombatDefinition {
  @override
  final String id;
  @override
  final String name;
  final String imageAsset;
  final int maxHp;
  final int maxStamina;
  final int strength;
  final int defense;
  final int speed;
  final AiProfile aiProfile;
  final List<String> availableSkills;

  const AllyTemplate({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.maxHp,
    required this.maxStamina,
    required this.strength,
    required this.defense,
    required this.speed,
    required this.aiProfile,
    required this.availableSkills,
  });

  factory AllyTemplate.fromJson(String id, Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;

    final int maxHealth = stats['maxHp'] ?? 50;
    final int maxStam = stats['maxStamina'] ?? 50;

    return AllyTemplate(
      id: id,
      name: json['name'] as String,
      imageAsset: json['imageAsset'] as String? ?? 'assets/images/player.png',
      maxHp: maxHealth,
      maxStamina: maxStam,
      strength: stats['strength'] ?? 10,
      defense: stats['defense'] ?? 5,
      speed: stats['speed'] ?? 10,
      aiProfile: AiProfile.fromJson(json['ai_profile'] as Map<String, dynamic>),
      availableSkills: List<String>.from(json['skills'] as List? ?? []),
    );
  }
}

class ActiveAlly implements CombatEntity {
  final String instanceId;
  final AllyTemplate template;
  final int _overrideMaxHp;
  final int _overrideMaxStamina;
  final int _overrideStrength;
  final int _overrideDefense;
  final String _overrideName;

  @override
  final RxInt hp;
  @override
  final RxInt stamina;
  @override
  final RxString lane;
  @override
  final RxBool isDead;

  ActiveAlly({
    required this.instanceId,
    required this.template,
    required int initialHp,
    required int initialStamina,
    required String initialLane,
    String? nameOverride,
    int? maxHpOverride,
    int? maxStaminaOverride,
    int? strengthOverride,
    int? defenseOverride,
  })  : _overrideName = nameOverride ?? template.name,
        _overrideMaxHp = maxHpOverride ?? template.maxHp,
        _overrideMaxStamina = maxStaminaOverride ?? template.maxStamina,
        _overrideStrength = strengthOverride ?? template.strength,
        _overrideDefense = defenseOverride ?? template.defense,
        hp = initialHp.obs,
        stamina = initialStamina.obs,
        lane = initialLane.obs,
        isDead = (initialHp <= 0).obs;

  @override
  String get id => instanceId;
  @override
  String get name => _overrideName;
  @override
  String get imageAsset => template.imageAsset;
  @override
  int get maxHp => _overrideMaxHp;
  @override
  int get maxStamina => _overrideMaxStamina;
  @override
  int get strength => _overrideStrength;
  @override
  int get defense => _overrideDefense;
  @override
  int get speed => template.speed;

  AiProfile get aiProfile => template.aiProfile;
  List<String> get availableSkills => template.availableSkills;
}
