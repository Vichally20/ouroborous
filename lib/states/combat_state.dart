import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/combat_models.dart';
import '../models/combat_event.dart';
import '../models/item.dart';
import '../models/skill.dart';
import '../states/player_state.dart';
import '../states/inventory_state.dart';
import '../game/story_engine.dart';

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

  final Random _random = Random();
  bool _playerActedThisRound = false;
  bool _enemiesActedThisRound = false;

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

  void startCombat(String encounterId, [String? victoryNodeId]) {
    isSandbox.value = false;
    onSandboxNextWave = null;
    onSandboxRetry = null;
    if (!encounters.containsKey(encounterId)) {
      addLog('Encounter $encounterId not found!');
      return;
    }

    final encounter = encounters[encounterId];

    final playerState = Get.find<PlayerState>();
    final activeHero = playerState.heroes[playerState.activeHeroIndex.value];
    
    playerMaxHp.value = activeHero.vitals.maxHp;
    playerHp.value = activeHero.vitals.currentHp;
    playerMaxStamina.value = activeHero.vitals.maxStamina;
    playerStamina.value = activeHero.vitals.currentStamina;
    
    playerName.value = activeHero.name;
    playerStrength.value = activeHero.attributes.strength;
    playerDexterity.value = activeHero.attributes.dexterity;
    playerIntelligence.value = activeHero.attributes.intelligence;
    playerConstitution.value = activeHero.attributes.constitution;
    playerSpeed.value = 10 + (activeHero.attributes.dexterity * 0.5).round();

    int totalArmor = 0;
    if (activeHero.loadout.head?.category == ItemCategory.apparel) totalArmor += activeHero.loadout.head!.statBonus;
    if (activeHero.loadout.chest?.category == ItemCategory.apparel) totalArmor += activeHero.loadout.chest!.statBonus;
    if (activeHero.loadout.leg?.category == ItemCategory.apparel) totalArmor += activeHero.loadout.leg!.statBonus;
    if (activeHero.loadout.secondaryHand?.category == ItemCategory.apparel) totalArmor += activeHero.loadout.secondaryHand!.statBonus;
    playerDefense.value = totalArmor > 0 ? totalArmor : 5;
    playerBleedStacks.value = 0;
    playerPoisonStacks.value = 0;

    final mainHandItem = activeHero.loadout.mainHand;
    playerWeaponName.value = mainHandItem?.name ?? 'Unarmed';
    playerWeaponBonus.value = mainHandItem?.statBonus ?? 0;
    playerWeaponRange.value = mainHandItem?.weaponRange ?? WeaponRange.melee;
    playerWeaponPerks.assignAll(mainHandItem?.perks ?? []);
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
    inCombat.value = true;

    addLog('${playerName.value} enters the fray equipped with ${playerWeaponName.value}!');
    addLog(encounter['description'] ?? 'Enemies surround you.');
    addLog('Combat initiated. Position: Back Line.');
    rollInitiativeAndStartRound();
  }

  void startSandboxCombat({
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
    onSandboxNextWave = onNextWave;
    onSandboxRetry = onRetry;

    playerMaxHp.value = heroMaxHp;
    playerHp.value = heroMaxHp;
    playerMaxStamina.value = heroMaxStamina;
    playerStamina.value = heroMaxStamina;

    playerName.value = 'Sandbox Gladiator';
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

    if (playerRoll >= enemyRoll) {
      addLog('Initiative Roll: You move first! (Spd: $playerSpd vs Enemy Spd: $maxEnemySpeed)');
      _processPlayerTurnStart();
    } else {
      isPlayerTurn.value = false;
      addLog('Initiative Roll: Enemies move first! (Spd: $maxEnemySpeed vs Your Spd: $playerSpd)');
      if (Get.testMode) {
        executeAllyTurnSequence().then((_) => executeEnemyTurnSequence());
      } else {
        Future.delayed(const Duration(milliseconds: 600), () async {
          await executeAllyTurnSequence();
          await executeEnemyTurnSequence();
        });
      }
    }
  }

  void _processPlayerTurnStart() {
    if (!inCombat.value) return;
    isPlayerTurn.value = true;
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
  }) {
    int hitChance = (100 + attackerDex - defenderSpeed).clamp(75, 100);
    bool isGlancing = !Get.testMode && (_random.nextInt(100) >= hitChance);

    int critChance = (5 + (attackerDex * 1.5).round()).clamp(0, 60);
    bool isCrit = !Get.testMode && !isGlancing && (_random.nextInt(100) < critChance);

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

    int effectiveDef = skill.ignoresArmor ? 0 : max(0, defenderDefense);
    double mitigationFactor = 100.0 / (100.0 + effectiveDef);
    if (defenderIsDefending) {
      mitigationFactor *= 0.5;
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

    int weaponDmg = max(10, playerWeaponBonus.value > 0 ? playerWeaponBonus.value : 12);
    final hitResult = calculateCombatHit(
      weaponDamage: weaponDmg,
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

    if (item.id == 'c1') {
      playerStamina.value = min(playerMaxStamina.value, playerStamina.value + 50);
      addLog('You inhale the Essence of Clarity. Stamina restored (+50).');
      showDamagePopup('player', '+50 STAM');
    } else if (item.id == 'c3') {
      playerHp.value = min(playerMaxHp.value, playerHp.value + 30);
      addLog('You consume the Mandrake Root. Wounds close (+30 HP).');
      showDamagePopup('player', '+30 HP');
    } else if (item.id == 'c4') {
      playerHp.value = min(playerMaxHp.value, playerHp.value + 40);
      playerStamina.value = min(playerMaxStamina.value, playerStamina.value + 40);
      Get.find<PlayerState>().depleteSanity(10);
      addLog('You shatter the Corrupted Soul Gem. Vitality rushes in (+40 HP/STAM, -10 Sanity).');
      showDamagePopup('player', '+40 HP/STAM');
    } else {
      addLog('This item cannot be used in combat.');
      return;
    }

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
      Future.delayed(const Duration(milliseconds: 600), () async {
        await executeAllyTurnSequence();
        await executeEnemyTurnSequence();
      });
    } else {
      addLog('Round complete. Preparing next round...');
      Future.delayed(const Duration(milliseconds: 600), () {
        if (inCombat.value) {
          rollInitiativeAndStartRound();
        }
      });
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
        addLog('${ally.name} advances to the Front Line.');
        await Future.delayed(const Duration(milliseconds: 800));
      } else if (scoreFlee > scoreAttack && ally.lane.value == 'front') {
        ally.lane.value = 'back';
        addLog('${ally.name} retreats to the Back Line.');
        await Future.delayed(const Duration(milliseconds: 800));
      } else {
        final target = livingEnemies[_random.nextInt(livingEnemies.length)];
        final bool allyIsRanged = ally.aiProfile.preferredRange > 0.5;
        final allyRange = allyIsRanged ? WeaponRange.ranged : WeaponRange.melee;

        if (!canReachTarget(ally.lane.value, target.lane.value, allyRange)) {
          if (ally.lane.value == 'back') {
            ally.lane.value = 'front';
            addLog('${ally.name} charges to the Front Line!');
            await Future.delayed(const Duration(milliseconds: 800));
          } else {
            addLog('${ally.name} attacks from afar, but falls short.');
            await Future.delayed(const Duration(milliseconds: 600));
          }
          checkVictoryOrDefeat();
          continue;
        }

        final String chosenSkillId = ally.availableSkills.isNotEmpty
            ? ally.availableSkills[_random.nextInt(ally.availableSkills.length)]
            : 'strike';
        final CombatSkill skill = SkillDictionary.getSkill(chosenSkillId);

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
          damageHits: [hitResult.finalDamage],
          isPlayerAction: true,
        );
        lastCombatEvent.value = allyEvent;
        attackEventId.value++;
        lastHitEnemyId.value = target.id;
        enemyHitEventId.value++;

        String mitPercent = ((1.0 - hitResult.mitigationFactor) * 100).clamp(0, 100).toStringAsFixed(0);
        addLog('${ally.name} strikes ${target.name} with ${skill.name} for ${hitResult.finalDamage} damage! (Armor blocked $mitPercent%)');
        await Future.delayed(const Duration(milliseconds: 1000));
        checkVictoryOrDefeat();
      }
    }
  }

  Future<void> executeEnemyTurnSequence() async {
    for (var enemy in enemies) {
      if (enemy.isDead.value) continue;
      if (!inCombat.value) return;

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

      double scoreAttack = enemy.aiProfile.aggression * 100.0;
      double scoreFlee = 0.0;
      double scoreAdvance = 0.0;

      if (enemy.hp.value < (enemy.maxHp * 0.3)) {
        scoreFlee = enemy.aiProfile.selfPreservation * 100.0;
      }

      final bool isFrontEmpty = enemies.where((e) => e.lane.value == 'front' && !e.isDead.value).isEmpty;
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
        enemy.lane.value = 'front';
        addLog('The ${enemy.name} advances to the Front Line.');
        await Future.delayed(const Duration(milliseconds: 1000));
      } else if (scoreFlee > scoreAttack && enemy.lane.value == 'front') {
        enemy.lane.value = 'back';
        addLog('The ${enemy.name} retreats to the Back Line.');
        await Future.delayed(const Duration(milliseconds: 1000));
      } else {
        final bool enemyIsRanged = enemy.aiProfile.preferredRange > 0.5;
        final enemyRange = enemyIsRanged ? WeaponRange.ranged : WeaponRange.melee;
        if (!canReachTarget(enemy.lane.value, playerLane.value, enemyRange)) {
          if (enemy.lane.value == 'back') {
            enemy.lane.value = 'front';
            addLog('The ${enemy.name} charges to the Front Line!');
            await Future.delayed(const Duration(milliseconds: 1000));
          } else {
            addLog('The ${enemy.name} snarls from afar, out of reach.');
            await Future.delayed(const Duration(milliseconds: 800));
          }
          checkVictoryOrDefeat();
          continue;
        }

        final String chosenSkillId = enemy.availableSkills.isNotEmpty
            ? enemy.availableSkills[_random.nextInt(enemy.availableSkills.length)]
            : 'strike';
        final CombatSkill skill = SkillDictionary.getSkill(chosenSkillId);

        ActiveAlly? targetAlly;
        final livingAllies = allies.where((a) => !a.isDead.value).toList();
        final frontAllies = livingAllies.where((a) => a.lane.value == 'front').toList();

        if (enemyRange == WeaponRange.melee && playerLane.value == 'back' && frontAllies.isNotEmpty) {
          targetAlly = frontAllies[_random.nextInt(frontAllies.length)];
        } else if (_random.nextBool() && livingAllies.isNotEmpty) {
          targetAlly = livingAllies[_random.nextInt(livingAllies.length)];
        }

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
            damageHits: [hitResult.finalDamage],
            isPlayerAction: false,
          );
          lastCombatEvent.value = enemyEvent;
          attackEventId.value++;
          lastHitEnemyId.value = targetAlly.id;
          enemyHitEventId.value++;

          String mitPercent = ((1.0 - hitResult.mitigationFactor) * 100).clamp(0, 100).toStringAsFixed(0);
          addLog('The ${enemy.name} uses ${skill.name} on ${targetAlly.name} for ${hitResult.finalDamage} damage. (Armor blocked $mitPercent%)');
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
          );
          playerHp.value = max(0, playerHp.value - hitResult.finalDamage);
          showDamagePopup('player', '-${hitResult.finalDamage} HP');

          int heal = skill.healAmount + hitResult.lifestealHeal;
          if (heal > 0) {
            enemy.hp.value = (enemy.hp.value + heal).clamp(0, enemy.maxHp);
            showDamagePopup(enemy.id, '+$heal HP');
          }

          final enemyEvent = CombatEvent(
            skillName: skill.name,
            weaponName: enemy.name,
            targetId: 'player',
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
        }
      }

      checkVictoryOrDefeat();
      await Future.delayed(const Duration(milliseconds: 1200));
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
          Future.delayed(const Duration(milliseconds: 600), () {
            if (inCombat.value) {
              rollInitiativeAndStartRound();
            }
          });
        }
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

    bool allDead = enemies.every((e) => e.isDead.value);
    if (allDead) {
      if (isSandbox.value) {
        addLog('SANDBOX VICTORY! Enemy defeated.');
        Get.snackbar(
          'PROVING GROUNDS VICTORY',
          'Wave conquered in the Sandbox Arena!',
          backgroundColor: const Color(0xFF162516),
          colorText: const Color(0xFFD4CFC7),
          borderRadius: 0,
          margin: const EdgeInsets.all(12),
        );
        return;
      }
      inCombat.value = false;
      addLog('VICTORY! You have vanquished the enemies.');
      
      final playerState = Get.find<PlayerState>();
      playerState.vitals.value.currentHp = playerHp.value;
      playerState.vitals.value.currentStamina = playerStamina.value;
      playerState.vitals.refresh();
      playerState.gainXp(50);
      
      Get.snackbar(
        'COMBAT VICTORY',
        'Enemies defeated! Gained 50 XP.',
        backgroundColor: const Color(0xFF162516),
        colorText: const Color(0xFFD4CFC7),
        borderRadius: 0,
        margin: const EdgeInsets.all(12),
      );

      // Route to aftermath node if one was provided
      if (currentVictoryNodeId.value != null) {
        Get.find<StoryEngine>().goToNode(currentVictoryNodeId.value!);
      }
      
      return;
    }

    if (playerHp.value <= 0) {
      playerHp.value = 0;
      if (isSandbox.value) {
        addLog('SANDBOX DEFEAT... Overcome in the Proving Grounds.');
        Get.snackbar(
          'ARENA DEFEAT',
          'You were overcome in the Sandbox Proving Grounds.',
          backgroundColor: const Color(0xFF330B0B),
          colorText: const Color(0xFFD4CFC7),
          borderRadius: 0,
          margin: const EdgeInsets.all(12),
        );
        return;
      }
      inCombat.value = false;
      addLog('DEFEAT... You fell in battle.');
      
      final playerState = Get.find<PlayerState>();
      playerState.vitals.value.currentHp = 1;
      playerState.vitals.refresh();

      Get.snackbar(
        'YOU WERE SLAIN',
        'Defeated in combat.',
        backgroundColor: const Color(0xFF330B0B),
        colorText: const Color(0xFFD4CFC7),
        borderRadius: 0,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  void escapeCombat() {
    inCombat.value = false;
    isSandbox.value = false;
    addLog('You retreated from the battle.');
    Get.snackbar(
      'RETREAT',
      'You fled back to safety.',
      backgroundColor: const Color(0xFF201B15),
      colorText: const Color(0xFFD4CFC7),
      borderRadius: 0,
      margin: const EdgeInsets.all(12),
    );
  }
}
