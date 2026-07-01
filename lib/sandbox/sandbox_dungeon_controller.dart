import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/combat_models.dart';
import '../models/item.dart';
import '../models/hero_character.dart';
import '../states/player_state.dart';
import '../states/combat_state.dart';

class SandboxDungeonController extends GetxController {
  // Navigation phase: 'setup' or 'arena'
  final phase = 'setup'.obs;

  // Bestiary & Hero reference
  final bestiary = <String, Enemy>{}.obs;
  final availableHeroes = <HeroCharacter>[].obs;
  final selectedHeroIndex = 0.obs;

  // Live Tunable Player Attributes
  final strength = 14.obs;
  final dexterity = 12.obs;
  final intelligence = 10.obs;
  final constitution = 14.obs;
  final insight = 10.obs;

  // Live Combat Vitals
  final maxHp = 120.obs;
  final currentHp = 120.obs;
  final maxStamina = 100.obs;
  final currentStamina = 100.obs;
  final playerAp = 3.obs;
  final maxAp = 3.obs;
  final playerLane = 'front'.obs; // 'front' or 'back'

  // Weapon Sandbox Loadout
  final availableWeapons = <ArtifactItem>[
    const ArtifactItem(
      id: 'sandbox_claymore',
      name: 'Blackiron Claymore (Heavy)',
      description: 'Massive meteoric iron greatsword. High scaling with Strength.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.relic,
      weight: 9.0,
      statBonus: 20,
      weaponRange: WeaponRange.melee,
      perks: ['execute', 'parry'],
    ),
    const ArtifactItem(
      id: 'sandbox_falchion',
      name: 'Sanguine Falchion',
      description: 'Razor-sharp curved blade designed to sever vessels.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.vitruvian,
      weight: 4.5,
      statBonus: 15,
      weaponRange: WeaponRange.melee,
      perks: ['bleed', 'expose_weakness'],
    ),
    const ArtifactItem(
      id: 'sandbox_staff',
      name: 'Hermetic Voidstaff',
      description: 'Alchemical conduit channeling destructive plasma at distance.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.relic,
      weight: 3.5,
      statBonus: 22,
      weaponRange: WeaponRange.ranged,
      perks: ['lock_on'],
    ),
    const ArtifactItem(
      id: 'sandbox_daggers',
      name: 'Twin Shadow Daggers',
      description: 'Lightweight dual blades for rapid back-line strikes.',
      category: ItemCategory.weapon,
      rarity: ItemRarity.unpolished,
      weight: 2.0,
      statBonus: 12,
      weaponRange: WeaponRange.melee,
      perks: ['bleed', 'parry'],
    ),
  ].obs;

  final selectedWeaponIndex = 0.obs;
  ArtifactItem get activeWeapon => availableWeapons[selectedWeaponIndex.value];

  // 30-Wave Engine State
  final currentWave = 1.obs;
  final totalWaves = 30;
  final currentEnemy = Rxn<Enemy>();
  final isWaveCompleted = false.obs;
  final isSandboxDefeat = false.obs;
  final isSandboxVictory = false.obs;

  // Feed & Effects
  final combatLogs = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    // Sync heroes from PlayerState if available
    if (Get.isRegistered<PlayerState>()) {
      final pState = Get.find<PlayerState>();
      if (pState.heroes.isNotEmpty) {
        availableHeroes.assignAll(pState.heroes);
      }
    }
    selectHero(0);

    // Load bestiary
    try {
      final bestiaryJson = await rootBundle.loadString('assets/data/bestiary.json');
      final Map<String, dynamic> bMap = json.decode(bestiaryJson);
      for (final key in bMap.keys) {
        bestiary[key] = Enemy.fromJson(key, bMap[key], 'front');
      }
    } catch (e) {
      debugPrint('Error loading sandbox bestiary: $e');
    }
  }

  void selectHero(int index) {
    if (availableHeroes.isNotEmpty && index >= 0 && index < availableHeroes.length) {
      selectedHeroIndex.value = index;
      final hero = availableHeroes[index];
      strength.value = hero.attributes.strength;
      dexterity.value = hero.attributes.dexterity;
      intelligence.value = hero.attributes.intelligence;
      constitution.value = hero.attributes.constitution;
      insight.value = hero.attributes.insight;
      recalculateVitals();
    }
  }

  void recalculateVitals() {
    // Scale HP and Stamina dynamically from Constitution and Strength/Dex
    final computedMaxHp = 50 + (constitution.value * 5);
    final computedMaxStam = 60 + (dexterity.value * 3) + (constitution.value * 2);

    maxHp.value = computedMaxHp;
    if (currentHp.value > maxHp.value || currentHp.value == 0) {
      currentHp.value = maxHp.value;
    }
    maxStamina.value = computedMaxStam;
    if (currentStamina.value > maxStamina.value || currentStamina.value == 0) {
      currentStamina.value = maxStamina.value;
    }
  }

  void adjustAttribute(String attr, int delta) {
    switch (attr) {
      case 'STR':
        strength.value = (strength.value + delta).clamp(1, 100);
        break;
      case 'DEX':
        dexterity.value = (dexterity.value + delta).clamp(1, 100);
        break;
      case 'INT':
        intelligence.value = (intelligence.value + delta).clamp(1, 100);
        break;
      case 'CON':
        constitution.value = (constitution.value + delta).clamp(1, 100);
        break;
      case 'INS':
        insight.value = (insight.value + delta).clamp(1, 100);
        break;
    }
    recalculateVitals();
    addLog('Tuned attribute $attr by ${delta >= 0 ? "+$delta" : delta}.');
  }

  void startDungeonRun() {
    isSandboxDefeat.value = false;
    isSandboxVictory.value = false;
    isWaveCompleted.value = false;
    recalculateVitals();

    final enemy = createWaveEnemy(currentWave.value);

    final combatController = Get.find<CombatController>();
    combatController.startSandboxCombat(
      heroMaxHp: maxHp.value,
      heroMaxStamina: maxStamina.value,
      heroStrength: strength.value,
      heroIntelligence: intelligence.value,
      heroConstitution: constitution.value,
      weaponName: activeWeapon.name,
      weaponBonus: activeWeapon.statBonus,
      weaponRange: activeWeapon.weaponRange,
      enemy: enemy,
      onNextWave: () => advanceSandboxWave(),
      onRetry: () => startDungeonRun(),
    );

    phase.value = 'arena';
  }

  void advanceSandboxWave() {
    if (currentWave.value < totalWaves) {
      currentWave.value += 1;
      final combatController = Get.find<CombatController>();
      final healAmt = (maxHp.value * 0.4).round();
      final newHp = (combatController.playerHp.value + healAmt).clamp(0, maxHp.value);

      final nextEnemy = createWaveEnemy(currentWave.value);

      combatController.startSandboxCombat(
        heroMaxHp: maxHp.value,
        heroMaxStamina: maxStamina.value,
        heroStrength: strength.value,
        heroIntelligence: intelligence.value,
        heroConstitution: constitution.value,
        weaponName: activeWeapon.name,
        weaponBonus: activeWeapon.statBonus,
        weaponRange: activeWeapon.weaponRange,
        enemy: nextEnemy,
        onNextWave: () => advanceSandboxWave(),
        onRetry: () => startDungeonRun(),
      );
      combatController.playerHp.value = newHp;
    } else {
      final combatController = Get.find<CombatController>();
      combatController.inCombat.value = false;
      combatController.isSandbox.value = false;
      phase.value = 'setup';
      Get.snackbar(
        'SANDBOX CONQUERED!',
        'You have defeated all $totalWaves waves in the Island of Skulls Proving Grounds!',
        backgroundColor: const Color(0xFF162516),
        colorText: Colors.amberAccent,
      );
    }
  }

  Enemy createWaveEnemy(int wave) {
    isWaveCompleted.value = false;
    final keys = bestiary.keys.toList();
    if (keys.isEmpty) {
      final fallback = Enemy(
        id: 'sandbox_guard_$wave',
        name: 'Skull Island Gladiator (Wave $wave)',
        imageAsset: 'assets/images/enemy_werewolf_black.png',
        maxHp: 50 + (wave * 15),
        maxStamina: 100,
        strength: 10 + (wave * 2),
        defense: 4 + wave,
        speed: 10,
        initialHp: 50 + (wave * 15),
        initialStamina: 100,
        initialLane: wave % 2 == 0 ? 'back' : 'front',
        aiProfile: const AiProfile(aggression: 0.8, selfPreservation: 0.2, preferredRange: 0.0),
        availableSkills: ['bite'],
      );
      currentEnemy.value = fallback;
      return fallback;
    }

    String templateKey;
    if (wave % 10 == 0) {
      templateKey = keys.contains('flesh_construct') ? 'flesh_construct' : keys.last;
    } else if (wave % 5 == 0) {
      templateKey = keys.contains('werewolf_alpha') ? 'werewolf_alpha' : keys[(wave - 1) % keys.length];
    } else {
      templateKey = keys[(wave - 1) % keys.length];
    }

    final template = bestiary[templateKey]!;
    
    final double healthScale = 1.0 + ((wave - 1) * 0.28);
    final double damageScale = 1.0 + ((wave - 1) * 0.18);
    final int scaledHp = (template.maxHp * healthScale).round();
    final int scaledStr = (template.strength * damageScale).round();
    final int scaledDef = template.defense + ((wave - 1) * 1.5).round();

    final enemyName = wave % 10 == 0
        ? 'Dungeon Sovereign: ${template.name}'
        : wave % 5 == 0
            ? 'Elite Vanguard: ${template.name}'
            : '${template.name} (W$wave)';

    final enemyLane = wave % 3 == 0 ? 'back' : 'front';

    final created = Enemy(
      id: 'wave_${wave}_${template.id}',
      name: enemyName,
      imageAsset: template.imageAsset,
      maxHp: scaledHp,
      maxStamina: template.maxStamina + (wave * 5),
      strength: scaledStr,
      defense: scaledDef,
      speed: template.speed,
      initialHp: scaledHp,
      initialStamina: template.maxStamina + (wave * 5),
      initialLane: enemyLane,
      aiProfile: template.aiProfile,
      availableSkills: template.availableSkills,
    );
    currentEnemy.value = created;
    addLog('─── WAVE $wave / $totalWaves ───');
    addLog('Spawned $enemyName in the ${enemyLane.toUpperCase()} line! (HP: $scaledHp, STR: $scaledStr, DEF: $scaledDef)');
    return created;
  }

  void addLog(String message) {
    combatLogs.insert(0, message);
    if (combatLogs.length > 50) {
      combatLogs.removeLast();
    }
  }
}
