import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/combat_models.dart';
import '../models/item.dart';
import '../states/player_state.dart';
import '../states/inventory_state.dart';
import '../game/story_engine.dart';

class CombatController extends GetxController {
  final inCombat = false.obs;
  final isPlayerTurn = true.obs;

  // Bestiary & Encounters
  final RxMap<String, Enemy> bestiary = <String, Enemy>{}.obs;
  final RxMap<String, dynamic> encounters = <String, dynamic>{}.obs;

  // Player combat vitals
  final playerHp = 100.obs;
  final playerMaxHp = 100.obs;
  final playerAp = 3.obs;
  final playerStamina = 100.obs;
  final playerMaxStamina = 100.obs;
  final playerLane = 'back'.obs; // 'back' or 'front'
  final hasMovedThisTurn = false.obs;
  final isDefending = false.obs;

  // Selected hero stats synced for scaling calculations
  final playerName = 'You'.obs;
  final playerStrength = 10.obs;
  final playerIntelligence = 10.obs;
  final playerConstitution = 10.obs;
  final playerWeaponName = 'Unarmed'.obs;
  final playerWeaponBonus = 0.obs;

  // Selected enemy for target targeting
  final selectedEnemyId = RxnString();

  // Enemies list
  final enemies = <Enemy>[].obs;

  // Combat Log feed
  final combatLogs = <String>[].obs;

  // Damage popups / feedback (e.g. Map of combatantId to floating text)
  final damagePopups = <String, String>{}.obs;

  final RxnString currentVictoryNodeId = RxnString();

  final Random _random = Random();

  @override
  void onInit() {
    super.onInit();
    _loadCombatData();
  }

  Future<void> _loadCombatData() async {
    try {
      final bestiaryJson = await rootBundle.loadString('assets/data/bestiary.json');
      final Map<String, dynamic> bMap = json.decode(bestiaryJson);
      for (final key in bMap.keys) {
        bestiary[key] = Enemy.fromJson(key, bMap[key], 'front');
      }

      final encountersJson = await rootBundle.loadString('assets/data/encounters.json');
      final Map<String, dynamic> eMap = json.decode(encountersJson);
      encounters.assignAll(eMap);
    } catch (e) {
      debugPrint('Error loading combat data: $e');
    }
  }

  void startCombat(String encounterId, [String? victoryNodeId]) {
    if (!encounters.containsKey(encounterId)) {
      addLog('Encounter $encounterId not found!');
      return;
    }

    final encounter = encounters[encounterId];

    final playerState = Get.find<PlayerState>();
    final activeHero = playerState.heroes[playerState.activeHeroIndex.value];
    
    // 1. Initialize player combat stats from PlayerState active hero
    playerMaxHp.value = activeHero.vitals.maxHp;
    playerHp.value = activeHero.vitals.currentHp;
    playerMaxStamina.value = activeHero.vitals.maxStamina;
    playerStamina.value = activeHero.vitals.currentStamina;
    
    // Copy active hero attributes
    playerName.value = activeHero.name;
    playerStrength.value = activeHero.attributes.strength;
    playerIntelligence.value = activeHero.attributes.intelligence;
    playerConstitution.value = activeHero.attributes.constitution;
    
    final mainHandItem = activeHero.loadout.mainHand;
    playerWeaponName.value = mainHandItem?.name ?? 'Unarmed';
    playerWeaponBonus.value = mainHandItem?.statBonus ?? 0;
    
    playerAp.value = 3;
    playerLane.value = 'back';
    hasMovedThisTurn.value = false;
    isDefending.value = false;
    isPlayerTurn.value = true;
    selectedEnemyId.value = null;
    damagePopups.clear();
    combatLogs.clear();

    // 2. Populate enemies from encounter definition
    final List<Enemy> spawnedEnemies = [];
    final List<dynamic> enemyList = encounter['enemies'];
    
    for (final eDef in enemyList) {
      final bestiaryId = eDef['bestiary_id'];
      final instanceId = eDef['id'];
      final lane = eDef['lane'];
      
      if (bestiary.containsKey(bestiaryId)) {
        spawnedEnemies.add(bestiary[bestiaryId]!.clone(instanceId, lane));
      }
    }
    enemies.value = spawnedEnemies;

    if (enemies.isNotEmpty) {
      selectedEnemyId.value = enemies[0].id;
    }

    currentVictoryNodeId.value = victoryNodeId;

    // 3. Mark inCombat as true
    inCombat.value = true;

    addLog('${playerName.value} enters the fray equipped with ${playerWeaponName.value}!');
    addLog(encounter['description'] ?? 'Enemies surround you.');
    addLog('Combat initiated. Position: Back Line.');
  }

  void addLog(String text) {
    combatLogs.insert(0, text); // Top of the list is newest
  }

  void selectEnemy(String id) {
    final enemy = enemies.firstWhereOrNull((e) => e.id == id);
    if (enemy != null && !enemy.isDead.value) {
      selectedEnemyId.value = id;
      addLog('Targeting: ${enemy.name}');
    }
  }

  void showDamagePopup(String targetId, String text) {
    damagePopups[targetId] = text;
    damagePopups.refresh();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (damagePopups[targetId] == text) {
        damagePopups.remove(targetId);
        damagePopups.refresh();
      }
    });
  }

  // Action 1: Move lane (costs 1 AP, 0 Stamina)
  void playerMove() {
    if (!isPlayerTurn.value || playerAp.value < 1) return;
    if (hasMovedThisTurn.value) {
      addLog('Cannot shift lanes again this turn.');
      return;
    }

    final newLane = playerLane.value == 'back' ? 'front' : 'back';
    playerLane.value = newLane;
    playerAp.value -= 1;
    hasMovedThisTurn.value = true;

    addLog('You shift position to the ${newLane == 'front' ? 'Front Line' : 'Back Line'}.');
    checkAutoEndTurn();
  }

  // Action 2: Attack (costs 1 AP + Stamina)
  bool playerAttack(int skillIndex) {
    if (!isPlayerTurn.value || playerAp.value < 1) return false;
    if (selectedEnemyId.value == null) {
      addLog('Select a target first.');
      return false;
    }

    final target = enemies.firstWhereOrNull((e) => e.id == selectedEnemyId.value);
    if (target == null || target.isDead.value) {
      addLog('Target is already dead.');
      return false;
    }

    int damage = 0;
    int staminaCost = 0;
    String skillName = '';

    if (skillIndex == 1) {
      skillName = 'Blood Falchion Strike';
      staminaCost = 20;
      
      double rawDmg = 10.0 + (playerStrength.value * 0.8) + (playerWeaponBonus.value * 1.5);
      damage = rawDmg.round();
      
      damage += _random.nextInt(6) - 3;
      if (damage < 5) damage = 5;
      
      if (playerLane.value == 'front') {
        damage = (damage * 1.5).round();
      } else {
        damage = (damage * 0.7).round();
      }
    } else if (skillIndex == 2) {
      skillName = 'Hermetic Firebolt';
      staminaCost = 40;
      
      double rawDmg = 15.0 + (playerIntelligence.value * 1.8);
      damage = rawDmg.round();
      
      damage += _random.nextInt(8) - 4;
      if (damage < 8) damage = 8;
    }

    if (playerStamina.value < staminaCost) {
      addLog('Too exhausted to use $skillName (Needs $staminaCost Stamina).');
      return false;
    }

    playerAp.value -= 1;
    playerStamina.value -= staminaCost;
    target.hp.value -= damage;
    showDamagePopup(target.id, '-$damage HP');

    if (skillIndex == 1 && playerLane.value == 'front') {
      addLog('Lunge! You execute $skillName from the Front Line for $damage physical damage.');
    } else if (skillIndex == 1 && playerLane.value == 'back') {
      addLog('Reach! You swipe with $skillName from the Back Line for $damage physical damage.');
    } else {
      addLog('Incantation! You launch $skillName at ${target.name} for $damage magical damage.');
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

  // Action 3: Defend (costs 1 AP, 0 Stamina, gains defense + stamina)
  void playerDefense() {
    if (!isPlayerTurn.value || playerAp.value < 1) return;

    playerAp.value -= 1;
    isDefending.value = true;
    
    final staminaGain = 30 + (playerConstitution.value * 1.5).round();
    playerStamina.value = min(playerMaxStamina.value, playerStamina.value + staminaGain);

    addLog('You raise your shield, bracing for attacks and restoring $staminaGain Stamina.');
    showDamagePopup('player', '+$staminaGain STAM');
    checkAutoEndTurn();
  }

  // Action 4: Use Item in Combat (costs 1 AP)
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
    if (inventoryItem.count > 1) {
      invState.addItem(ArtifactItem(
        id: inventoryItem.id,
        name: inventoryItem.name,
        description: inventoryItem.description,
        category: inventoryItem.category,
        rarity: inventoryItem.rarity,
        weight: inventoryItem.weight,
        equipSlot: inventoryItem.equipSlot,
        statBonus: inventoryItem.statBonus,
        count: inventoryItem.count - 1,
      ));
    }

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
    addLog('Turn ended. Enemies prepare to strike...');
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      executeEnemyTurnSequence();
    });
  }

  Future<void> executeEnemyTurnSequence() async {
    for (var enemy in enemies) {
      if (enemy.isDead.value) continue;
      if (!inCombat.value) return;

      // UTILITY AI LOGIC
      // Available actions: 
      // 1. Move Forward (if back)
      // 2. Move Backward (if front)
      // 3. Attack Player

      double scoreAttack = enemy.aiProfile.aggression * 100.0;
      double scoreFlee = 0.0;
      double scoreAdvance = 0.0;

      // If health is critically low, increase self preservation score
      if (enemy.hp.value < (enemy.maxHp * 0.3)) {
        scoreFlee = enemy.aiProfile.selfPreservation * 100.0;
      }

      // Range preferences
      if (enemy.lane.value == 'back' && enemy.aiProfile.preferredRange == 0.0) {
        scoreAdvance = 100.0; // Wants to get into melee
      } else if (enemy.lane.value == 'front' && enemy.aiProfile.preferredRange > 0.0) {
        scoreFlee += 50.0; // Wants to get back to range
      }

      // Add a little randomness so they aren't 100% predictable
      scoreAttack += _random.nextInt(20);
      scoreFlee += _random.nextInt(20);
      scoreAdvance += _random.nextInt(20);

      // Execute highest scoring action
      if (scoreAdvance > scoreAttack && scoreAdvance > scoreFlee && enemy.lane.value == 'back') {
        enemy.lane.value = 'front';
        addLog('The ${enemy.name} advances to the Front Line.');
        await Future.delayed(const Duration(milliseconds: 1000));
      } else if (scoreFlee > scoreAttack && enemy.lane.value == 'front') {
        enemy.lane.value = 'back';
        addLog('The ${enemy.name} retreats to the Back Line.');
        await Future.delayed(const Duration(milliseconds: 1000));
      } else {
        // Attack
        int baseDmg = enemy.strength + _random.nextInt(8) - 4;

        if (playerLane.value == 'back' && enemy.lane.value == 'front') {
          baseDmg = (baseDmg * 0.6).round();
        }
        
        if (enemy.lane.value == 'back') {
          baseDmg = (baseDmg * 0.5).round();
        }

        if (isDefending.value) {
          baseDmg = (baseDmg * 0.5).round();
        }

        if (baseDmg < 1) baseDmg = 1;

        playerHp.value -= baseDmg;
        showDamagePopup('player', '-$baseDmg HP');
        
        if (isDefending.value) {
          addLog('The ${enemy.name} strikes your shield for $baseDmg damage.');
        } else {
          addLog('The ${enemy.name} hits you for $baseDmg physical damage.');
        }
      }

      checkVictoryOrDefeat();
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    if (inCombat.value) {
      isPlayerTurn.value = true;
      playerAp.value = 3;
      hasMovedThisTurn.value = false;
      isDefending.value = false;

      final staminaDrip = 15;
      playerStamina.value = min(playerMaxStamina.value, playerStamina.value + staminaDrip);

      addLog('Your turn begins. (+15 Stamina).');
      showDamagePopup('player', '+$staminaDrip STAM');
    }
  }

  void checkVictoryOrDefeat() {
    bool allDead = enemies.every((e) => e.isDead.value);
    if (allDead) {
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
