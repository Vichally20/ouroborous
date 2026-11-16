import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/combat_models.dart';
import '../models/combat_event.dart';
import '../models/combat_stats.dart';
import '../models/consumable_effects.dart';
import '../models/talent_node.dart';
import '../models/item.dart';
import '../models/skill.dart';
import '../states/player_state.dart';
import '../states/inventory_state.dart';
import '../states/settings_state.dart';
import '../states/town_state.dart';
import '../game/story_engine.dart';
import '../ui/widgets/toast.dart';

class CombatHitResult {
  final int rawDamage;
  final int skillDamage;
  final double mitigationFactor;
  final int finalDamage;
  final bool isCrit;
  final bool isGlancing;
  final int lifestealHeal;
  final int bleedApplied;
  final int poisonApplied;

  CombatHitResult({
    required this.rawDamage,
    required this.skillDamage,
    required this.mitigationFactor,
    required this.finalDamage,
    required this.isCrit,
    required this.isGlancing,
    this.lifestealHeal = 0,
    this.bleedApplied = 0,
    this.poisonApplied = 0,
  });
}

class CombatController extends GetxController {
  StoryEngine get _storyEngine => Get.find<StoryEngine>();

  final inCombat = false.obs;
  final isSandbox = false.obs;

  /// Set once this battle is won or lost, so the result (log line, XP, interest,
  /// toast) happens exactly once however many times the outcome is checked.
  bool _resolved = false;
  bool get isResolved => _resolved;
  VoidCallback? onSandboxNextWave;
  VoidCallback? onSandboxRetry;

  final isPlayerTurn = true.obs;

  // Bestiary, Allies & Encounters
  final RxMap<String, EnemyTemplate> bestiary = <String, EnemyTemplate>{}.obs;
  final RxMap<String, AllyTemplate> allyRoster = <String, AllyTemplate>{}.obs;
  final RxMap<String, dynamic> encounters = <String, dynamic>{}.obs;

  // Player combat vitals & attributes
  final playerHp = 100.obs;
  final playerMaxHp = 100.obs;
  final playerAp = 3.obs;
  final playerStamina = 100.obs;
  final playerMaxStamina = 100.obs;
  final playerLane = 'back'.obs; // 'back' or 'front'
  final hasMovedThisTurn = false.obs;
  final isDefending = false.obs;

  final playerName = 'You'.obs;
  final playerStrength = 10.obs;
  final playerDexterity = 10.obs;
  final playerIntelligence = 10.obs;
  final playerConstitution = 10.obs;
  final playerSpeed = 10.obs;
  final playerDefense = 5.obs;
  final playerBleedStacks = 0.obs;
  final playerPoisonStacks = 0.obs;
  final playerWeaponPerks = <String>[].obs;

  final playerWeaponName = 'Unarmed'.obs;
  final playerWeaponBonus = 0.obs;
  final playerWeaponRange = WeaponRange.melee.obs;
  final playerSkills = <String>['blood_falchion_strike', 'hermetic_firebolt'].obs;

  /// Talent effects of the hero in this fight (none in the sandbox).
  TalentEffect playerTalents = TalentEffect.none;
  bool playerTwoHanded = false;

  /// Weapon damage used for the player's strikes (and talent counterattacks).
  int get playerWeaponDamage => max(10, playerWeaponBonus.value > 0 ? playerWeaponBonus.value : 12);

  // Selected enemy for target targeting
  final selectedEnemyId = RxnString();

  // Enemies list
  final enemies = <ActiveEnemy>[].obs;

  // Allies list
  final allies = <ActiveAlly>[].obs;

  // Combat Log feed
  final combatLogs = <String>[].obs;

  // Damage popups / feedback
  final damagePopups = <String, String>{}.obs;

  // ─── Animation Triggers (Reactive Key pattern) ───
  final RxInt attackEventId = 0.obs;
  final Rxn<CombatEvent> lastCombatEvent = Rxn<CombatEvent>();
  final RxInt enemyHitEventId = 0.obs;
  final RxnString lastHitEnemyId = RxnString();

  final RxnString currentVictoryNodeId = RxnString();

  /// Story scene a lost fight leads to; when null, retreating reloads the last save.
  final RxnString currentDefeatNodeId = RxnString();

  /// Encounter being fought, so Retry restarts the right fight.
  String? currentEncounterId;

  /// Who acts this round, in order: 'player', ally ids, enemy ids.
  final turnOrder = <String>[].obs;

  /// Whose action is resolving right now ('player', an ally id or an enemy id).
  final RxnString currentActorId = RxnString();

  /// Round number, shown in the turn banner.
  final round = 0.obs;

  final Random _random = Random();
  bool _playerActedThisRound = false;
  bool _enemiesActedThisRound = false;

  Duration get _combatDelayDuration {
    if (Get.testMode) return Duration.zero;
    final settings = Get.isRegistered<SettingsState>() ? Get.find<SettingsState>() : null;
    final double seconds = settings?.attackDelay.value ?? 2.0;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  Future<void> _delayBetweenAttacks() async {
    if (Get.testMode) return;
    final duration = _combatDelayDuration;
    if (duration > Duration.zero) {
      await Future.delayed(duration);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadCombatData();
  }

  Future<void> _loadCombatData() async {
    try {
      final bestiaryStr = await rootBundle.loadString('assets/data/bestiary.json');
      final bestiaryJson = jsonDecode(bestiaryStr) as Map<String, dynamic>;
      for (final entry in bestiaryJson.entries) {
        bestiary[entry.key] = EnemyTemplate.fromJson(entry.key, entry.value);
      }

      final alliesStr = await rootBundle.loadString('assets/data/allies.json');
      final alliesJson = jsonDecode(alliesStr) as Map<String, dynamic>;
      for (final entry in alliesJson.entries) {
        allyRoster[entry.key] = AllyTemplate.fromJson(entry.key, entry.value);
      }

      final encountersStr = await rootBundle.loadString('assets/data/encounters.json');
      final encountersJson = jsonDecode(encountersStr) as Map<String, dynamic>;
      encounters.addAll(encountersJson);
    } catch (e) {
      debugPrint('Error loading combat data: $e');
    }
  }

  void startCombat(String encounterId, [String? victoryNodeId, String? defeatNodeId]) {
    isSandbox.value = false;
    onSandboxNextWave = null;
    onSandboxRetry = null;
    if (!encounters.containsKey(encounterId)) {
      addLog('Encounter $encounterId not found!');
      return;
    }

    final encounter = encounters[encounterId];
    currentEncounterId = encounterId;
    round.value = 0;

    final playerState = Get.find<PlayerState>();
    final activeHero = playerState.heroes[playerState.activeHeroIndex.value];
    
    playerMaxHp.value = activeHero.vitals.maxHp;
    playerHp.value = activeHero.vitals.currentHp;
    playerMaxStamina.value = activeHero.vitals.maxStamina;
    playerStamina.value = activeHero.vitals.currentStamina;
    
    playerName.value = activeHero.name;
    final stats = HeroCombatStats.of(activeHero);
    playerStrength.value = stats.strength;
    playerDexterity.value = stats.dexterity;
    playerIntelligence.value = stats.intelligence;
    playerConstitution.value = stats.constitution;
    playerSpeed.value = stats.speed;
    playerDefense.value = stats.defense;
    playerBleedStacks.value = 0;
    playerPoisonStacks.value = 0;
    playerTalents = stats.talents;
    playerTwoHanded = stats.twoHanded;

    playerWeaponName.value = stats.weaponName;
    playerWeaponBonus.value = activeHero.loadout.mainHand?.power ?? 0;
    playerWeaponRange.value = stats.weaponRange;
    playerWeaponPerks.assignAll(stats.weaponPerks);
    playerSkills.assignAll(
      activeHero.availableSkills.isNotEmpty
          ? activeHero.availableSkills
          : activeHero.characterClass.availableSkills,
    );
    
    playerAp.value = 3;
    playerLane.value = 'back';
    hasMovedThisTurn.value = false;
    isDefending.value = false;
    selectedEnemyId.value = null;
    damagePopups.clear();
    combatLogs.clear();
    attackEventId.value = 0;
    lastCombatEvent.value = null;

    final List<ActiveEnemy> spawnedEnemies = [];
    final List<dynamic> enemyList = encounter['enemies'];
    for (final eDef in enemyList) {
      final bestiaryId = eDef['bestiary_id'];
      if (bestiary.containsKey(bestiaryId)) {
        final tmpl = bestiary[bestiaryId]!;
        spawnedEnemies.add(ActiveEnemy(
          instanceId: eDef['id'],
          template: tmpl,
          initialHp: tmpl.maxHp,
          initialStamina: tmpl.maxStamina,
          initialLane: eDef['lane'],
        ));
      }
    }
    enemies.value = spawnedEnemies;

    final List<ActiveAlly> spawnedAllies = [];
    final List<dynamic>? allyList = encounter['allies'];
    if (allyList != null) {
      for (final aDef in allyList) {
        final allyId = aDef['ally_id'];
        if (allyRoster.containsKey(allyId)) {
          final tmpl = allyRoster[allyId]!;
          spawnedAllies.add(ActiveAlly(
            instanceId: aDef['id'],
            template: tmpl,
            initialHp: tmpl.maxHp,
            initialStamina: tmpl.maxStamina,
            initialLane: aDef['lane'] ?? 'front',
          ));
        }
      }
    }
    allies.value = spawnedAllies;

    if (enemies.isNotEmpty) {
      selectedEnemyId.value = enemies[0].id;
    }

    currentVictoryNodeId.value = victoryNodeId;
    currentDefeatNodeId.value = defeatNodeId;
    _resolved = false;
    inCombat.value = true;

    addLog('${playerName.value} enters the fray equipped with ${playerWeaponName.value}!');
    addLog(encounter['description'] ?? 'Enemies surround you.');
    addLog('Combat initiated. Position: Back Line.');
    rollInitiativeAndStartRound();
  }

  void startSandboxCombat({
    String? heroName,
    required int heroMaxHp,
    required int heroMaxStamina,
    required int heroStrength,
    required int heroIntelligence,
    required int heroConstitution,
    int heroDexterity = 12,
    int heroSpeed = 16,
    int heroDefense = 10,
    required String weaponName,
    required int weaponBonus,
    required WeaponRange weaponRange,
    List<String> weaponPerks = const [],
    List<String> heroSkills = const ['blood_falchion_strike', 'hermetic_firebolt'],
    required ActiveEnemy enemy,
    String? allyKey,
    VoidCallback? onNextWave,
    VoidCallback? onRetry,
  }) {
    isSandbox.value = true;
    currentEncounterId = null;
    round.value = 0;
    playerTalents = TalentEffect.none;
    playerTwoHanded = false;
    onSandboxNextWave = onNextWave;
    onSandboxRetry = onRetry;

    playerMaxHp.value = heroMaxHp;
    playerHp.value = heroMaxHp;
    playerMaxStamina.value = heroMaxStamina;
    playerStamina.value = heroMaxStamina;

    playerName.value = heroName ?? 'Sandbox Gladiator';
    playerStrength.value = heroStrength;
    playerDexterity.value = heroDexterity;
    playerIntelligence.value = heroIntelligence;
    playerConstitution.value = heroConstitution;
    playerSpeed.value = heroSpeed;
    playerDefense.value = heroDefense;
    playerBleedStacks.value = 0;
    playerPoisonStacks.value = 0;

    playerWeaponName.value = weaponName;
    playerWeaponBonus.value = weaponBonus;
    playerWeaponRange.value = weaponRange;
    playerWeaponPerks.assignAll(weaponPerks);
    playerSkills.assignAll(heroSkills);

    playerAp.value = 3;
    playerLane.value = 'back';
    hasMovedThisTurn.value = false;
    isDefending.value = false;
    selectedEnemyId.value = null;
    damagePopups.clear();
    combatLogs.clear();
    attackEventId.value = 0;
    lastCombatEvent.value = null;

    enemies.value = [enemy];
    allies.clear();
    if (allyKey != null && allyRoster.containsKey(allyKey)) {
      spawnAlly(allyKey, 'front');
      addLog('Allied ${allyRoster[allyKey]!.name} joined the front line!');
    }
    selectedEnemyId.value = enemy.id;
    currentVictoryNodeId.value = null;
    currentDefeatNodeId.value = null;

    _resolved = false;
    inCombat.value = true;

    addLog('Entering Island of Skulls Sandbox Proving Grounds...');
    addLog('Equipped: $weaponName [Bonus +$weaponBonus]');
    addLog('Combat initiated against ${enemy.name}. Position: Back Line.');
    rollInitiativeAndStartRound();
  }

  void rollInitiativeAndStartRound() {
    _playerActedThisRound = false;
    _enemiesActedThisRound = false;

    int maxEnemySpeed = enemies.isEmpty ? 10 : enemies.fold(10, (prev, e) => max(prev, e.speed));
    int playerSpd = playerSpeed.value;
    double playerRoll = Get.testMode ? 99999.0 : playerSpd * _random.nextDouble();
    double enemyRoll = Get.testMode ? 0.0 : maxEnemySpeed * _random.nextDouble();

    round.value++;
    final allyIds = allies.where((a) => !a.isDead.value).map((a) => a.id);
    final enemyIds = enemies.where((e) => !e.isDead.value).map((e) => e.id);
    turnOrder.assignAll(playerRoll >= enemyRoll
        ? ['player', ...allyIds, ...enemyIds]
        : [...allyIds, ...enemyIds, 'player']);

    if (playerRoll >= enemyRoll) {
      addLog('Initiative Roll: You move first! (Spd: $playerSpd vs Enemy Spd: $maxEnemySpeed)');
      _processPlayerTurnStart();
    } else {
      isPlayerTurn.value = false;
      addLog('Initiative Roll: Enemies move first! (Spd: $maxEnemySpeed vs Your Spd: $playerSpd)');
      if (Get.testMode) {
        executeAllyTurnSequence().then((_) => executeEnemyTurnSequence());
      } else {
        Future.delayed(_combatDelayDuration, () async {
          await executeAllyTurnSequence();
          await executeEnemyTurnSequence();
        });
      }
    }
  }

  void _processPlayerTurnStart() {
    if (!inCombat.value) return;
    isPlayerTurn.value = true;
    currentActorId.value = 'player';
    playerAp.value = 3;
    hasMovedThisTurn.value = false;
    isDefending.value = false;

    int staminaDrip = 15 + (playerSpeed.value * 0.2).round();
    playerStamina.value = min(playerMaxStamina.value, playerStamina.value + staminaDrip);
    showDamagePopup('player', '+$staminaDrip STAM');

    if (playerBleedStacks.value > 0) {
      int bleedDmg = playerBleedStacks.value * 4;
      playerHp.value = max(0, playerHp.value - bleedDmg);
      showDamagePopup('player', '-$bleedDmg BLEED');
      addLog('Bleed inflicts $bleedDmg direct damage on you!');
      playerBleedStacks.value = max(0, playerBleedStacks.value - 1);
    }
    if (playerPoisonStacks.value > 0 && playerHp.value > 0) {
      int poisonDmg = playerPoisonStacks.value * 3;
      playerHp.value = max(0, playerHp.value - poisonDmg);
      showDamagePopup('player', '-$poisonDmg POISON');
      addLog('Poison courses through your veins for $poisonDmg damage!');
      playerPoisonStacks.value = max(0, playerPoisonStacks.value - 1);
    }
    checkVictoryOrDefeat();
    if (inCombat.value) planEnemyIntents();
  }

  CombatHitResult calculateCombatHit({
    required int weaponDamage,
    required int attackerStr,
    required int attackerDex,
    required int attackerInt,
    required int attackerSpeed,
    required int defenderDefense,
    required int defenderSpeed,
    required CombatSkill skill,
    required String attackerLane,
    required String defenderLane,
    required bool defenderIsDefending,
    List<String> attackerPerks = const [],
    TalentEffect attackerTalents = TalentEffect.none,
    TalentEffect defenderTalents = TalentEffect.none,
    bool attackerTwoHanded = false,
    bool targetExecutable = false,
    bool? forceCrit,
    bool deterministic = false,
  }) {
    int hitChance = ((100 + attackerDex - defenderSpeed).clamp(75, 100) - defenderTalents.evasion).clamp(50, 100);
    bool isGlancing = !deterministic && !Get.testMode && (_random.nextInt(100) >= hitChance);

    int critChance = (5 + (attackerDex * 1.5).round() + attackerTalents.critChance).clamp(0, 75);
    bool isCrit = forceCrit ?? (!deterministic && !Get.testMode && !isGlancing && (_random.nextInt(100) < critChance));

    double rawOutput = 0.0;
    if (skill.type == SkillType.magical) {
      rawOutput = weaponDamage + (attackerInt * 0.8);
    } else {
      rawOutput = weaponDamage + (attackerStr * 0.5);
    }
    int rawDamage = max(1, rawOutput.round());

    double laneMult = 1.0;
    if (attackerLane == 'front') {
      laneMult = skill.frontLineMultiplier;
    } else if (attackerLane == 'back') {
      laneMult = skill.backLineMultiplier;
    }
    if (attackerLane == 'back' && defenderLane == 'front') {
      laneMult *= 0.8;
    }
    double skillDmg = rawDamage * skill.multiplier * laneMult;

    // Talents: attacker's damage bonus (+ two-handed mastery), defender's damage taken.
    double talentMult = 1.0 + attackerTalents.damageDealtPct;
    if (attackerTwoHanded) talentMult += attackerTalents.twoHandedDamagePct;
    talentMult *= (1.0 + defenderTalents.damageTakenPct);
    if (targetExecutable) talentMult *= attackerTalents.executeMultiplier;
    skillDmg *= max(0.1, talentMult);

    int effectiveDef = skill.ignoresArmor ? 0 : (max(0, defenderDefense) * (1.0 - attackerTalents.armorIgnore)).round();
    double mitigationFactor = 100.0 / (100.0 + effectiveDef);
    if (defenderIsDefending) {
      mitigationFactor *= (0.5 - defenderTalents.guardBonus).clamp(0.2, 1.0);
    }

    double finalHit = skillDmg * mitigationFactor;
    if (isCrit) {
      finalHit *= 1.5;
    } else if (isGlancing) {
      finalHit *= 0.5;
    }
    int finalDamage = max(1, finalHit.round());

    int lifestealHeal = 0;
    int bleedApplied = 0;
    int poisonApplied = 0;

    if (!isGlancing) {
      if (attackerPerks.contains('bleed') || skill.effectDescription.toLowerCase().contains('bleed')) {
        bleedApplied = 2;
      }
      if (isCrit) {
        bleedApplied += attackerTalents.bleedOnCrit;
      }
      if (attackerPerks.contains('poison') || skill.effectDescription.toLowerCase().contains('poison')) {
        poisonApplied = 2;
      }
      if (attackerPerks.contains('lifesteal') || skill.healAmount > 0 || skill.effectDescription.toLowerCase().contains('life drain')) {
        lifestealHeal = max(1, (finalDamage * 0.15).round()) + skill.healAmount;
      }
    }

    return CombatHitResult(
      rawDamage: rawDamage,
      skillDamage: skillDmg.round(),
      mitigationFactor: mitigationFactor,
      finalDamage: finalDamage,
      isCrit: isCrit,
      isGlancing: isGlancing,
      lifestealHeal: lifestealHeal,
      bleedApplied: bleedApplied,
      poisonApplied: poisonApplied,
    );
  }

  void addLog(String text) {
    combatLogs.insert(0, text);
    if (combatLogs.length > 50) {
      combatLogs.removeLast();
    }
  }

  void showDamagePopup(String targetId, String text) {
    damagePopups[targetId] = text;
    if (!Get.testMode) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (damagePopups[targetId] == text) {
          damagePopups.remove(targetId);
        }
      });
    }
  }

  bool canReachTarget(String attackerLane, String targetLane, WeaponRange range) {
    if (range == WeaponRange.ranged) return true;
    if (attackerLane == 'front' || targetLane == 'front') return true;
    return false;
  }

  void selectEnemy(String enemyId) {
    selectedEnemyId.value = enemyId;
  }

  void playerMove() {
    if (!isPlayerTurn.value || playerAp.value < 1) return;

    final newLane = playerLane.value == 'back' ? 'front' : 'back';
    playerLane.value = newLane;
    playerAp.value -= 1;
    hasMovedThisTurn.value = true;

    addLog('You shift position to the ${newLane == 'front' ? 'Front Line' : 'Back Line'}.');
    refreshEnemyIntents();
    checkAutoEndTurn();
  }

  bool playerAttack(int skillIndex) {
    if (!isPlayerTurn.value || playerAp.value < 1) return false;

    CombatSkill skill;
    if (skillIndex >= 1 && skillIndex <= playerSkills.length) {
      skill = SkillDictionary.getSkill(playerSkills[skillIndex - 1]);
    } else {
      skill = SkillDictionary.getSkill('strike');
    }

    if (playerStamina.value < skill.staminaCost) {
      addLog('Too exhausted to use ${skill.name} (Needs ${skill.staminaCost} Stamina).');
      return false;
    }

    if (skill.target == SkillTarget.self || skill.target == SkillTarget.allAllies) {
      playerAp.value -= skill.apCost;
      playerStamina.value = (playerStamina.value - skill.staminaCost + skill.staminaRestore).clamp(0, playerMaxStamina.value);
      if (skill.staminaRestore > 0) {
        showDamagePopup('player', '+${skill.staminaRestore} STAM');
      }
      if (skill.id == 'shield_brace') {
        isDefending.value = true;
        refreshEnemyIntents();
        addLog('${playerName.value} raises a shield to brace against incoming attacks!');
      } else if (skill.id == 'retreat') {
        playerLane.value = 'back';
        addLog('${playerName.value} melts into the shadows and retreats to the Back Line.');
      } else {
        addLog('${playerName.value} uses ${skill.name}.');
      }
      return true;
    }

    if (selectedEnemyId.value == null) {
      addLog('Select a target first.');
      return false;
    }

    final target = enemies.firstWhereOrNull((e) => e.id == selectedEnemyId.value);
    if (target == null || target.isDead.value) {
      addLog('Target is already dead.');
      return false;
    }

    if (skill.type != SkillType.magical &&
        !canReachTarget(playerLane.value, target.lane.value, playerWeaponRange.value)) {
      addLog('${target.name} is out of range! Move to the Front Line or equip a ranged weapon.');
      return false;
    }

    final hitResult = calculateCombatHit(
      weaponDamage: playerWeaponDamage,
      attackerStr: playerStrength.value,
      attackerDex: playerDexterity.value,
      attackerInt: playerIntelligence.value,
      attackerSpeed: playerSpeed.value,
      defenderDefense: target.defense,
      defenderSpeed: target.speed,
      skill: skill,
      attackerLane: playerLane.value,
      defenderLane: target.lane.value,
      defenderIsDefending: false,
      attackerPerks: playerWeaponPerks,
      attackerTalents: playerTalents,
      attackerTwoHanded: playerTwoHanded,
      targetExecutable: target.bleedStacks.value > 0 && target.hp.value < target.maxHp * 0.3,
    );

    playerAp.value -= skill.apCost;
    playerStamina.value -= skill.staminaCost;
    target.hp.value = max(0, target.hp.value - hitResult.finalDamage);

    if (hitResult.bleedApplied > 0) {
      target.bleedStacks.value += hitResult.bleedApplied;
      showDamagePopup(target.id, '+${hitResult.bleedApplied} BLEED');
    }
    if (hitResult.poisonApplied > 0) {
      target.poisonStacks.value += hitResult.poisonApplied;
      showDamagePopup(target.id, '+${hitResult.poisonApplied} POISON');
    }
    if (hitResult.lifestealHeal > 0) {
      playerHp.value = min(playerMaxHp.value, playerHp.value + hitResult.lifestealHeal);
      showDamagePopup('player', '+${hitResult.lifestealHeal} HP');
    }

    final event = CombatEvent(
      skillName: skill.name,
      weaponName: playerWeaponName.value,
      targetId: target.id,
      attackerId: 'player',
      isCritical: hitResult.isCrit,
      damageHits: [hitResult.finalDamage],
      perks: playerWeaponPerks,
      isPlayerAction: true,
    );
    lastCombatEvent.value = event;
    attackEventId.value++;
    lastHitEnemyId.value = target.id;
    enemyHitEventId.value++;

    String mitPercent = ((1.0 - hitResult.mitigationFactor) * 100).clamp(0, 100).toStringAsFixed(0);
    if (hitResult.isCrit) {
      addLog('CRITICAL HIT! You strike ${target.name} with ${skill.name} for ${hitResult.finalDamage} damage! (Armor blocked $mitPercent%)');
    } else if (hitResult.isGlancing) {
      addLog('Glancing Blow! Your strike grazes ${target.name} for ${hitResult.finalDamage} damage.');
    } else {
      addLog('You strike ${target.name} with ${skill.name} for ${hitResult.finalDamage} damage. (Armor blocked $mitPercent%)');
    }

    if (target.hp.value <= 0) {
      target.hp.value = 0;
      target.isDead.value = true;
      addLog('The ${target.name} collapses!');
      final nextLiving = enemies.firstWhereOrNull((e) => !e.isDead.value);
      selectedEnemyId.value = nextLiving?.id;
    }

    checkVictoryOrDefeat();
    if (inCombat.value) {
      checkAutoEndTurn();
    }
    return true;
  }

  void playerDefend() {
    if (!isPlayerTurn.value || playerAp.value < 1) return;

    playerAp.value -= 1;
    isDefending.value = true;
    
    final staminaGain = 30 + (playerConstitution.value * 1.5).round();
    playerStamina.value = min(playerMaxStamina.value, playerStamina.value + staminaGain);

    addLog('You raise your shield, bracing for attacks and restoring $staminaGain Stamina.');
    showDamagePopup('player', '+$staminaGain STAM');
    refreshEnemyIntents();
    checkAutoEndTurn();
  }

  void useCombatItem(ArtifactItem item) {
    if (!isPlayerTurn.value || playerAp.value < 1) return;

    final invState = Get.find<InventoryState>();
    final inventoryItem = invState.ledger.firstWhereOrNull((i) => i.id == item.id);
    if (inventoryItem == null || inventoryItem.count <= 0) {
      addLog('Item not available.');
      return;
    }

    final effect = ConsumableEffect.of(item.id);
    if (effect == null) {
      addLog('This item cannot be used in combat.');
      return;
    }
    playerHp.value = (playerHp.value + effect.hp).clamp(0, playerMaxHp.value);
    playerStamina.value = (playerStamina.value + effect.stamina).clamp(0, playerMaxStamina.value);
    if (effect.sanity != 0) {
      final vitals = Get.find<PlayerState>().vitals;
      vitals.value.currentSanity = (vitals.value.currentSanity + effect.sanity).clamp(0, vitals.value.maxSanity);
      vitals.refresh();
    }
    addLog('${effect.flavour} (${effect.summary})');
    showDamagePopup('player', effect.summary.split(', ').first);

    invState.removeItem(item.id);
    playerAp.value -= 1;
    checkAutoEndTurn();
  }

  void checkAutoEndTurn() {
    if (playerAp.value <= 0) {
      endPlayerTurn();
    }
  }

  void endPlayerTurn() {
    if (!isPlayerTurn.value) return;
    isPlayerTurn.value = false;
    _playerActedThisRound = true;
    addLog('Turn ended.');

    if (!_enemiesActedThisRound) {
      addLog('Allies & Enemies prepare to strike...');
      if (Get.testMode) {
        executeAllyTurnSequence().then((_) => executeEnemyTurnSequence());
      } else {
        Future.delayed(_combatDelayDuration, () async {
          await executeAllyTurnSequence();
          await executeEnemyTurnSequence();
        });
      }
    } else {
      addLog('Round complete. Preparing next round...');
      if (Get.testMode) {
        if (inCombat.value) rollInitiativeAndStartRound();
      } else {
        Future.delayed(_combatDelayDuration, () {
          if (inCombat.value) {
            rollInitiativeAndStartRound();
          }
        });
      }
    }
  }

  void spawnAlly(String allyKey, [String lane = 'front']) {
    if (allyRoster.containsKey(allyKey)) {
      final tmpl = allyRoster[allyKey]!;
      final instanceId = '${allyKey}_${DateTime.now().millisecondsSinceEpoch}';
      allies.add(ActiveAlly(
        instanceId: instanceId,
        template: tmpl,
        initialHp: tmpl.maxHp,
        initialStamina: tmpl.maxStamina,
        initialLane: lane,
      ));
      addLog('${tmpl.name} joins the fight on your side!');
    }
  }

  Future<void> executeAllyTurnSequence() async {
    for (var ally in allies) {
      if (ally.isDead.value) continue;
      if (!inCombat.value) return;
      currentActorId.value = ally.id;

      ally.ap.value = ally.maxAp;
      int staminaDrip = 15 + (ally.speed * 0.2).round();
      ally.stamina.value = min(ally.maxStamina, ally.stamina.value + staminaDrip);

      if (ally.bleedStacks.value > 0) {
        int bleedDmg = ally.bleedStacks.value * 4;
        ally.hp.value = max(0, ally.hp.value - bleedDmg);
        showDamagePopup(ally.id, '-$bleedDmg BLEED');
        addLog('Bleed inflicts $bleedDmg damage on ${ally.name}!');
        ally.bleedStacks.value = max(0, ally.bleedStacks.value - 1);
      }
      if (ally.poisonStacks.value > 0 && ally.hp.value > 0) {
        int poisonDmg = ally.poisonStacks.value * 3;
        ally.hp.value = max(0, ally.hp.value - poisonDmg);
        showDamagePopup(ally.id, '-$poisonDmg POISON');
        addLog('Poison inflicts $poisonDmg damage on ${ally.name}!');
        ally.poisonStacks.value = max(0, ally.poisonStacks.value - 1);
      }
      if (ally.hp.value <= 0) {
        ally.isDead.value = true;
        continue;
      }

      while (ally.ap.value > 0 && !ally.isDead.value && inCombat.value) {
        final livingEnemies = enemies.where((e) => !e.isDead.value).toList();
        if (livingEnemies.isEmpty) return;

        double scoreAttack = ally.aiProfile.aggression * 100.0;
        double scoreAdvance = 0.0;
        double scoreFlee = 0.0;

        if (ally.hp.value < (ally.maxHp * 0.3)) {
          scoreFlee = ally.aiProfile.selfPreservation * 100.0;
        }

        final bool isFrontEmpty = allies.where((a) => a.lane.value == 'front' && !a.isDead.value).isEmpty && playerLane.value != 'front';
        if (ally.lane.value == 'back' && ally.aiProfile.preferredRange == 0.0) {
          scoreAdvance = 100.0;
        } else if (ally.lane.value == 'front' && ally.aiProfile.preferredRange > 0.0) {
          scoreFlee += 50.0;
        }
        if (ally.lane.value == 'back' && isFrontEmpty && ally.aiProfile.preferredRange < 0.8) {
          scoreAdvance += 150.0;
        }

        scoreAttack += _random.nextInt(20);
        scoreFlee += _random.nextInt(20);
        scoreAdvance += _random.nextInt(20);

        if (scoreAdvance > scoreAttack && scoreAdvance > scoreFlee && ally.lane.value == 'back') {
          ally.lane.value = 'front';
          ally.ap.value -= 1;
          addLog('${ally.name} advances to the Front Line.');
          await _delayBetweenAttacks();
        } else if (scoreFlee > scoreAttack && ally.lane.value == 'front') {
          ally.lane.value = 'back';
          ally.ap.value -= 1;
          addLog('${ally.name} retreats to the Back Line.');
          await _delayBetweenAttacks();
        } else {
          final target = livingEnemies[_random.nextInt(livingEnemies.length)];
          final bool allyIsRanged = ally.aiProfile.preferredRange > 0.5;
          final allyRange = allyIsRanged ? WeaponRange.ranged : WeaponRange.melee;

          if (!canReachTarget(ally.lane.value, target.lane.value, allyRange)) {
            if (ally.lane.value == 'back' && ally.ap.value >= 1) {
              ally.lane.value = 'front';
              ally.ap.value -= 1;
              addLog('${ally.name} charges to the Front Line!');
              await _delayBetweenAttacks();
              continue;
            } else {
              addLog('${ally.name} attacks from afar, but falls short.');
              await _delayBetweenAttacks();
              break;
            }
          }

          final String chosenSkillId = ally.availableSkills.isNotEmpty
              ? ally.availableSkills[_random.nextInt(ally.availableSkills.length)]
              : 'strike';
          CombatSkill skill = SkillDictionary.getSkill(chosenSkillId);

          if (ally.ap.value < skill.apCost || ally.stamina.value < skill.staminaCost) {
            skill = SkillDictionary.getSkill('strike');
            if (ally.ap.value < skill.apCost || ally.stamina.value < skill.staminaCost) {
              break;
            }
          }

          ally.ap.value -= skill.apCost;
          ally.stamina.value = max(0, ally.stamina.value - skill.staminaCost);

          final hitResult = calculateCombatHit(
            weaponDamage: 12,
            attackerStr: ally.strength,
            attackerDex: 10,
            attackerInt: 10,
            attackerSpeed: ally.speed,
            defenderDefense: target.defense,
            defenderSpeed: target.speed,
            skill: skill,
            attackerLane: ally.lane.value,
            defenderLane: target.lane.value,
            defenderIsDefending: false,
          );

          target.hp.value = max(0, target.hp.value - hitResult.finalDamage);
          showDamagePopup(target.id, '-${hitResult.finalDamage} HP');

          if (hitResult.bleedApplied > 0) {
            target.bleedStacks.value += hitResult.bleedApplied;
          }
          if (hitResult.poisonApplied > 0) {
            target.poisonStacks.value += hitResult.poisonApplied;
          }

          if (target.hp.value <= 0) {
            target.hp.value = 0;
            target.isDead.value = true;
            addLog('The ${target.name} collapses under ${ally.name}\'s attack!');
            final nextLiving = enemies.firstWhereOrNull((e) => !e.isDead.value);
            selectedEnemyId.value = nextLiving?.id;
          }

          final allyEvent = CombatEvent(
            skillName: skill.name,
            weaponName: ally.name,
            targetId: target.id,
            attackerId: ally.id,
            isCritical: hitResult.isCrit,
            damageHits: [hitResult.finalDamage],
            isPlayerAction: true,
          );
          lastCombatEvent.value = allyEvent;
          attackEventId.value++;
          lastHitEnemyId.value = target.id;
          enemyHitEventId.value++;

          String mitPercent = ((1.0 - hitResult.mitigationFactor) * 100).clamp(0, 100).toStringAsFixed(0);
          addLog('${ally.name} strikes ${target.name} with ${skill.name} for ${hitResult.finalDamage} damage! (Armor blocked $mitPercent%)');
          await _delayBetweenAttacks();
          checkVictoryOrDefeat();
        }
      }
    }
  }

  Future<void> executeEnemyTurnSequence() async {
    for (var enemy in enemies) {
      if (enemy.isDead.value) continue;
      if (!inCombat.value || _resolved) return;
      currentActorId.value = enemy.id;

      enemy.ap.value = enemy.maxAp;
      int staminaDrip = 15 + (enemy.speed * 0.2).round();
      enemy.stamina.value = min(enemy.maxStamina, enemy.stamina.value + staminaDrip);

      if (enemy.bleedStacks.value > 0) {
        int bleedDmg = enemy.bleedStacks.value * 4;
        enemy.hp.value = max(0, enemy.hp.value - bleedDmg);
        showDamagePopup(enemy.id, '-$bleedDmg BLEED');
        addLog('Bleed inflicts $bleedDmg damage on ${enemy.name}!');
        enemy.bleedStacks.value = max(0, enemy.bleedStacks.value - 1);
      }
      if (enemy.poisonStacks.value > 0 && enemy.hp.value > 0) {
        int poisonDmg = enemy.poisonStacks.value * 3;
        enemy.hp.value = max(0, enemy.hp.value - poisonDmg);
        showDamagePopup(enemy.id, '-$poisonDmg POISON');
        addLog('Poison inflicts $poisonDmg damage on ${enemy.name}!');
        enemy.poisonStacks.value = max(0, enemy.poisonStacks.value - 1);
      }
      if (enemy.hp.value <= 0) {
        enemy.isDead.value = true;
        continue;
      }

      // First action follows the intent shown to the player, if it still makes sense.
      EnemyIntent? planned = enemy.intent.value;
      enemy.intent.value = null;

      while (enemy.ap.value > 0 && !enemy.isDead.value && inCombat.value) {
        final move = (planned != null && _intentStillValid(enemy, planned))
            ? planned
            : _decideEnemyMove(enemy, ap: enemy.ap.value, stamina: enemy.stamina.value);
        planned = null;

        if (move.kind == IntentKind.advance || move.kind == IntentKind.charge) {
          enemy.lane.value = 'front';
          enemy.ap.value -= 1;
          addLog(move.kind == IntentKind.charge
              ? 'The ${enemy.name} charges to the Front Line!'
              : 'The ${enemy.name} advances to the Front Line.');
          await _delayBetweenAttacks();
          continue;
        }
        if (move.kind == IntentKind.retreat) {
          enemy.lane.value = 'back';
          enemy.ap.value -= 1;
          addLog('The ${enemy.name} retreats to the Back Line.');
          await _delayBetweenAttacks();
          continue;
        }
        if (move.kind == IntentKind.hold) {
          addLog('The ${enemy.name} snarls from afar, out of reach.');
          await _delayBetweenAttacks();
          break;
        }

        {
          final enemyRange = _enemyRange(enemy);
          CombatSkill skill = SkillDictionary.getSkill(move.skillId ?? 'strike');
          if (enemy.ap.value < skill.apCost || enemy.stamina.value < skill.staminaCost) {
            skill = SkillDictionary.getSkill('strike');
            if (enemy.ap.value < skill.apCost || enemy.stamina.value < skill.staminaCost) {
              break;
            }
          }

          enemy.ap.value -= skill.apCost;
          enemy.stamina.value = max(0, enemy.stamina.value - skill.staminaCost);

          final ActiveAlly? targetAlly = move.targetId == null || move.targetId == 'player'
              ? null
              : allies.firstWhereOrNull((a) => a.id == move.targetId && !a.isDead.value);
          assert(enemyRange == WeaponRange.melee || enemyRange == WeaponRange.ranged);

          if (targetAlly != null) {
            final hitResult = calculateCombatHit(
              weaponDamage: 12,
              attackerStr: enemy.strength,
              attackerDex: 10,
              attackerInt: 10,
              attackerSpeed: enemy.speed,
              defenderDefense: targetAlly.defense,
              defenderSpeed: targetAlly.speed,
              skill: skill,
              attackerLane: enemy.lane.value,
              defenderLane: targetAlly.lane.value,
              defenderIsDefending: false,
            );
            targetAlly.hp.value = max(0, targetAlly.hp.value - hitResult.finalDamage);
            showDamagePopup(targetAlly.id, '-${hitResult.finalDamage} HP');

            if (targetAlly.hp.value <= 0) {
              targetAlly.hp.value = 0;
              targetAlly.isDead.value = true;
              addLog('${targetAlly.name} has fallen in battle!');
            }

            int heal = skill.healAmount + hitResult.lifestealHeal;
            if (heal > 0) {
              enemy.hp.value = (enemy.hp.value + heal).clamp(0, enemy.maxHp);
              showDamagePopup(enemy.id, '+$heal HP');
            }

            final enemyEvent = CombatEvent(
              skillName: skill.name,
              weaponName: enemy.name,
              targetId: targetAlly.id,
              attackerId: enemy.id,
              isCritical: hitResult.isCrit,
              damageHits: [hitResult.finalDamage],
              isPlayerAction: false,
            );
            lastCombatEvent.value = enemyEvent;
            attackEventId.value++;
            lastHitEnemyId.value = targetAlly.id;
            enemyHitEventId.value++;

            String mitPercent = ((1.0 - hitResult.mitigationFactor) * 100).clamp(0, 100).toStringAsFixed(0);
            addLog('The ${enemy.name} uses ${skill.name} on ${targetAlly.name} for ${hitResult.finalDamage} damage. (Armor blocked $mitPercent%)');
            await _delayBetweenAttacks();
          } else {
            final hitResult = calculateCombatHit(
              weaponDamage: 12,
              attackerStr: enemy.strength,
              attackerDex: 10,
              attackerInt: 10,
              attackerSpeed: enemy.speed,
              defenderDefense: playerDefense.value,
              defenderSpeed: playerSpeed.value,
              skill: skill,
              attackerLane: enemy.lane.value,
              defenderLane: playerLane.value,
              defenderIsDefending: isDefending.value,
              defenderTalents: playerTalents,
            );
            playerHp.value = max(0, playerHp.value - hitResult.finalDamage);
            showDamagePopup('player', '-${hitResult.finalDamage} HP');
            if (isDefending.value && playerHp.value > 0) {
              _applyBlockTalents(enemy);
            }

            int heal = skill.healAmount + hitResult.lifestealHeal;
            if (heal > 0) {
              enemy.hp.value = (enemy.hp.value + heal).clamp(0, enemy.maxHp);
              showDamagePopup(enemy.id, '+$heal HP');
            }

            final enemyEvent = CombatEvent(
              skillName: skill.name,
              weaponName: enemy.name,
              targetId: 'player',
              attackerId: enemy.id,
              isCritical: hitResult.isCrit,
              damageHits: [hitResult.finalDamage],
              isPlayerAction: false,
            );
            lastCombatEvent.value = enemyEvent;
            attackEventId.value++;
            lastHitEnemyId.value = 'player';
            enemyHitEventId.value++;

            String mitPercent = ((1.0 - hitResult.mitigationFactor) * 100).clamp(0, 100).toStringAsFixed(0);
            if (isDefending.value) {
              addLog('The ${enemy.name} uses ${skill.name} on your shield for ${hitResult.finalDamage} damage. (Armor blocked $mitPercent%)');
            } else {
              addLog('The ${enemy.name} uses ${skill.name} for ${hitResult.finalDamage} damage. (Armor blocked $mitPercent%)');
            }
            await _delayBetweenAttacks();
          }
        }
        checkVictoryOrDefeat();
      }
    }

    _enemiesActedThisRound = true;
    if (inCombat.value) {
      if (!_playerActedThisRound) {
        _processPlayerTurnStart();
      } else {
        addLog('Round complete. Preparing next round...');
        if (Get.testMode) {
          if (inCombat.value) rollInitiativeAndStartRound();
        } else {
          Future.delayed(_combatDelayDuration, () {
            if (inCombat.value) {
              rollInitiativeAndStartRound();
            }
          });
        }
      }
    }
  }

  WeaponRange _enemyRange(ActiveEnemy enemy) =>
      enemy.aiProfile.preferredRange > 0.5 ? WeaponRange.ranged : WeaponRange.melee;

  /// Decides one action for [enemy] given the AP and stamina it will have.
  /// Same scoring as before; used both to plan the visible intent and during the enemy turn.
  EnemyIntent _decideEnemyMove(ActiveEnemy enemy, {required int ap, required int stamina}) {
    double scoreAttack = enemy.aiProfile.aggression * 100.0;
    double scoreFlee = 0.0;
    double scoreAdvance = 0.0;

    if (enemy.hp.value < (enemy.maxHp * 0.3)) {
      scoreFlee = enemy.aiProfile.selfPreservation * 100.0;
    }
    final bool isFrontEmpty = enemies.where((e) => e.lane.value == 'front' && !e.isDead.value && e != enemy).isEmpty;
    if (enemy.lane.value == 'back' && enemy.aiProfile.preferredRange == 0.0) {
      scoreAdvance = 100.0;
    } else if (enemy.lane.value == 'front' && enemy.aiProfile.preferredRange > 0.0) {
      scoreFlee += 50.0;
    }
    if (enemy.lane.value == 'back' && isFrontEmpty && enemy.aiProfile.preferredRange < 0.8) {
      scoreAdvance += 150.0;
    }
    scoreAttack += _random.nextInt(20);
    scoreFlee += _random.nextInt(20);
    scoreAdvance += _random.nextInt(20);

    if (scoreAdvance > scoreAttack && scoreAdvance > scoreFlee && enemy.lane.value == 'back') {
      return const EnemyIntent(IntentKind.advance);
    }
    if (scoreFlee > scoreAttack && enemy.lane.value == 'front') {
      return const EnemyIntent(IntentKind.retreat);
    }

    final enemyRange = _enemyRange(enemy);
    if (!canReachTarget(enemy.lane.value, playerLane.value, enemyRange)) {
      return enemy.lane.value == 'back' && ap >= 1
          ? const EnemyIntent(IntentKind.charge)
          : const EnemyIntent(IntentKind.hold);
    }

    // Only damaging skills are attacks. Self/ally skills (Retreat, Alpha Howl) have no
    // effect system yet and used to "hit" for 1, so they're not picked as attacks.
    final attacks = enemy.availableSkills.where((id) {
      final sk = SkillDictionary.getSkill(id);
      return sk.multiplier > 0 && (sk.target == SkillTarget.singleEnemy || sk.target == SkillTarget.allEnemies);
    }).toList();
    String skillId = attacks.isNotEmpty ? attacks[_random.nextInt(attacks.length)] : 'strike';
    final chosen = SkillDictionary.getSkill(skillId);
    if (ap < chosen.apCost || stamina < chosen.staminaCost) skillId = 'strike';

    final livingAllies = allies.where((a) => !a.isDead.value).toList();
    final frontAllies = livingAllies.where((a) => a.lane.value == 'front').toList();
    String targetId = 'player';
    if (enemyRange == WeaponRange.melee && playerLane.value == 'back' && frontAllies.isNotEmpty) {
      targetId = frontAllies[_random.nextInt(frontAllies.length)].id;
    } else if (_random.nextBool() && livingAllies.isNotEmpty) {
      targetId = livingAllies[_random.nextInt(livingAllies.length)].id;
    }
    return EnemyIntent(IntentKind.attack, skillId: skillId, targetId: targetId);
  }

  bool _intentStillValid(ActiveEnemy enemy, EnemyIntent intent) {
    switch (intent.kind) {
      case IntentKind.advance:
      case IntentKind.charge:
        return enemy.lane.value == 'back';
      case IntentKind.retreat:
        return enemy.lane.value == 'front';
      case IntentKind.hold:
        return !canReachTarget(enemy.lane.value, playerLane.value, _enemyRange(enemy));
      case IntentKind.attack:
        if (!canReachTarget(enemy.lane.value, playerLane.value, _enemyRange(enemy))) return false;
        final t = intent.targetId;
        return t == null || t == 'player' || allies.any((a) => a.id == t && !a.isDead.value);
    }
  }

  /// Expected damage of [enemy] using [skillId] on [targetId], with no crit or glance.
  int _estimateEnemyHit(ActiveEnemy enemy, String skillId, String targetId) {
    final skill = SkillDictionary.getSkill(skillId);
    final ally = targetId == 'player' ? null : allies.firstWhereOrNull((a) => a.id == targetId);
    return calculateCombatHit(
      weaponDamage: 12,
      attackerStr: enemy.strength,
      attackerDex: 10,
      attackerInt: 10,
      attackerSpeed: enemy.speed,
      defenderDefense: ally?.defense ?? playerDefense.value,
      defenderSpeed: ally?.speed ?? playerSpeed.value,
      skill: skill,
      attackerLane: enemy.lane.value,
      defenderLane: ally?.lane.value ?? playerLane.value,
      defenderIsDefending: ally == null && isDefending.value,
      defenderTalents: ally == null ? playerTalents : TalentEffect.none,
      deterministic: true,
    ).finalDamage;
  }

  /// Commits every living enemy to its next move and shows it as an intent.
  void planEnemyIntents() {
    for (final enemy in enemies) {
      if (enemy.isDead.value) {
        enemy.intent.value = null;
        continue;
      }
      final stamina = min(enemy.maxStamina, enemy.stamina.value + 15 + (enemy.speed * 0.2).round());
      final move = _decideEnemyMove(enemy, ap: enemy.maxAp, stamina: stamina);
      enemy.intent.value = move.kind == IntentKind.attack
          ? move.withEstimate(_estimateEnemyHit(enemy, move.skillId!, move.targetId ?? 'player'))
          : move;
    }
  }

  /// After the player moves or braces: keep each enemy's plan but update reach and damage.
  void refreshEnemyIntents() {
    for (final enemy in enemies) {
      final intent = enemy.intent.value;
      if (intent == null || enemy.isDead.value) continue;
      final reach = canReachTarget(enemy.lane.value, playerLane.value, _enemyRange(enemy));
      if (intent.kind == IntentKind.attack && !reach) {
        enemy.intent.value = EnemyIntent(enemy.lane.value == 'back' ? IntentKind.charge : IntentKind.hold);
      } else if (intent.kind == IntentKind.hold && reach) {
        final skillId = enemy.availableSkills.firstWhere((id) {
          final sk = SkillDictionary.getSkill(id);
          return sk.multiplier > 0 && (sk.target == SkillTarget.singleEnemy || sk.target == SkillTarget.allEnemies);
        }, orElse: () => 'strike');
        enemy.intent.value = EnemyIntent(IntentKind.attack,
            skillId: skillId, targetId: 'player', estimatedDamage: _estimateEnemyHit(enemy, skillId, 'player'));
      } else if (intent.kind == IntentKind.attack) {
        enemy.intent.value = intent.withEstimate(_estimateEnemyHit(enemy, intent.skillId!, intent.targetId ?? 'player'));
      }
    }
  }

  // ─── Player-side previews for the skill hand ───

  /// Hand slot index -> skill. Slot 0 is the basic strike; 1.. are the hero's skills.
  CombatSkill skillForSlot(int slot) =>
      slot >= 1 && slot <= playerSkills.length ? SkillDictionary.getSkill(playerSkills[slot - 1]) : SkillDictionary.getSkill('strike');

  bool skillReaches(int slot, ActiveEnemy target) {
    final skill = skillForSlot(slot);
    if (skill.target == SkillTarget.self || skill.target == SkillTarget.allAllies) return true;
    return skill.type == SkillType.magical || canReachTarget(playerLane.value, target.lane.value, playerWeaponRange.value);
  }

  /// (normal hit, critical hit) the skill in [slot] would deal to [target] right now.
  (int, int)? previewSkillDamage(int slot, ActiveEnemy target) {
    final skill = skillForSlot(slot);
    if (skill.target == SkillTarget.self || skill.target == SkillTarget.allAllies) return null;
    CombatHitResult hit(bool crit) => calculateCombatHit(
          weaponDamage: playerWeaponDamage,
          attackerStr: playerStrength.value,
          attackerDex: playerDexterity.value,
          attackerInt: playerIntelligence.value,
          attackerSpeed: playerSpeed.value,
          defenderDefense: target.defense,
          defenderSpeed: target.speed,
          skill: skill,
          attackerLane: playerLane.value,
          defenderLane: target.lane.value,
          defenderIsDefending: false,
          attackerPerks: playerWeaponPerks,
          attackerTalents: playerTalents,
          attackerTwoHanded: playerTwoHanded,
          targetExecutable: target.bleedStacks.value > 0 && target.hp.value < target.maxHp * 0.3,
          forceCrit: crit,
          deterministic: true,
        );
    return (hit(false).finalDamage, hit(true).finalDamage);
  }

  /// Restart the current encounter at full health (story) or replay the sandbox wave.
  void retryCombat() {
    if (isSandbox.value) {
      if (onSandboxRetry != null) {
        onSandboxRetry!();
      } else {
        escapeCombat();
      }
      return;
    }
    final id = currentEncounterId;
    if (id == null) {
      finishCombatDefeat();
      return;
    }
    final playerState = Get.find<PlayerState>();
    playerState.vitals.value.currentHp = playerState.vitals.value.maxHp;
    playerState.vitals.value.currentStamina = playerState.vitals.value.maxStamina;
    playerState.vitals.refresh();
    startCombat(id, currentVictoryNodeId.value, currentDefeatNodeId.value);
  }

  /// Shield Wall / Vanguard's Retribution: effects when an attack lands on you while you defend.
  void _applyBlockTalents(ActiveEnemy attacker) {
    final t = playerTalents;
    if (t.staminaOnBlock > 0) {
      playerStamina.value = min(playerMaxStamina.value, playerStamina.value + t.staminaOnBlock);
      addLog('Shield Wall: the blow feeds you +${t.staminaOnBlock} Stamina.');
    }
    if (t.counterOnBlock > 0 && !attacker.isDead.value) {
      final counter = max(1, ((playerWeaponDamage + playerStrength.value * 0.5) * t.counterOnBlock).round());
      attacker.hp.value = max(0, attacker.hp.value - counter);
      showDamagePopup(attacker.id, '-$counter COUNTER');
      addLog("Vanguard's Retribution: you counter the ${attacker.name} for $counter damage.");
      if (attacker.hp.value <= 0) {
        attacker.isDead.value = true;
        addLog('The ${attacker.name} collapses!');
      }
    }
  }

  void checkVictoryOrDefeat() {
    for (final e in enemies) {
      if (!e.isDead.value && e.hp.value <= 0) {
        e.hp.value = 0;
        e.isDead.value = true;
        addLog('The ${e.name} collapses!');
      }
    }
    for (final a in allies) {
      if (!a.isDead.value && a.hp.value <= 0) {
        a.hp.value = 0;
        a.isDead.value = true;
        addLog('${a.name} has fallen in battle!');
      }
    }

    if (_resolved) return;

    bool allDead = enemies.every((e) => e.isDead.value);
    if (allDead) {
      _resolved = true;
      if (isSandbox.value) {
        addLog('SANDBOX VICTORY! Enemy defeated.');
        showToast('PROVING GROUNDS VICTORY', 'Wave conquered in the Sandbox Arena!', tone: ToastTone.success);
        return;
      }
      addLog('VICTORY! You have vanquished the enemies.');
      
      final playerState = Get.find<PlayerState>();
      playerState.vitals.value.currentHp = playerHp.value;
      playerState.vitals.value.currentStamina = playerStamina.value;
      playerState.vitals.refresh();
      playerState.gainXp(50);
      final interest = Get.isRegistered<TownState>() ? Get.find<TownState>().accrueInterest() : 0;
      if (interest > 0) addLog('The Counting House credits $interest crowns of interest.');

      showToast('COMBAT VICTORY', interest > 0 ? 'Enemies defeated! Gained 50 XP · +$interest crowns interest.' : 'Enemies defeated! Gained 50 XP.', tone: ToastTone.success);
      
      return;
    }

    if (playerHp.value <= 0) {
      playerHp.value = 0;
      _resolved = true;
      if (isSandbox.value) {
        addLog('SANDBOX DEFEAT... Overcome in the Proving Grounds.');
        showToast('ARENA DEFEAT', 'You were overcome in the Sandbox Proving Grounds.', tone: ToastTone.danger);
        return;
      }
      addLog('DEFEAT... You fell in battle.');
      
      final playerState = Get.find<PlayerState>();
      playerState.vitals.value.currentHp = 1;
      playerState.vitals.refresh();

      showToast('YOU WERE SLAIN', 'Defeated in combat.', tone: ToastTone.danger);
    }
  }

  void finishCombatVictory() {
    inCombat.value = false;
    if (currentVictoryNodeId.value != null) {
      Get.find<StoryEngine>().goToNode(currentVictoryNodeId.value!);
    }
  }

  void finishCombatDefeat() {
    inCombat.value = false;
  }

  void escapeCombat() {
    final dropped = !isSandbox.value && Get.isRegistered<TownState>() ? Get.find<TownState>().dropPurseOnFlee() : 0;
    inCombat.value = false;
    isSandbox.value = false;
    addLog(dropped > 0 ? 'You retreated, scattering $dropped crowns behind you.' : 'You retreated from the battle.');
    showToast('RETREAT', dropped > 0 ? 'You fled back to safety, dropping $dropped crowns.' : 'You fled back to safety.');
  }
}
