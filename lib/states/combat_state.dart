import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/item.dart';
import '../states/player_state.dart';
import '../states/inventory_state.dart';

class EnemyCombatant {
  final String id;
  final String name;
  final String imageAsset;
  final int maxHp;
  final RxInt hp;
  final RxString lane; // 'front' or 'back'
  final RxBool isDead;

  EnemyCombatant({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.maxHp,
    required int initialHp,
    required String initialLane,
  })  : hp = initialHp.obs,
        lane = initialLane.obs,
        isDead = (initialHp <= 0).obs;
}

class CombatController extends GetxController {
  final inCombat = false.obs;
  final isPlayerTurn = true.obs;

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
  final enemies = <EnemyCombatant>[].obs;

  // Combat Log feed
  final combatLogs = <String>[].obs;

  // Damage popups / feedback (e.g. Map of combatantId to floating text)
  final damagePopups = <String, String>{}.obs;

  final Random _random = Random();

  void startCombat() {
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

    // 2. Populate enemies
    enemies.value = [
      EnemyCombatant(
        id: 'enemy_orange',
        name: 'Feral Werewolf',
        imageAsset: 'assets/images/enemy_werewolf_orange.png',
        maxHp: 45,
        initialHp: 45,
        initialLane: 'front',
      ),
      EnemyCombatant(
        id: 'enemy_black',
        name: 'Shadow Werewolf',
        imageAsset: 'assets/images/enemy_werewolf_black.png',
        maxHp: 40,
        initialHp: 40,
        initialLane: 'back',
      ),
      EnemyCombatant(
        id: 'enemy_silver',
        name: 'Alpha Werewolf',
        imageAsset: 'assets/images/enemy_werewolf_silver.png',
        maxHp: 70,
        initialHp: 70,
        initialLane: 'back',
      ),
    ];

    // Select the first enemy by default
    selectedEnemyId.value = enemies[0].id;

    // 3. Mark inCombat as true
    inCombat.value = true;

    addLog('${playerName.value} enters the Breach equipped with ${playerWeaponName.value}!');
    addLog('A howl echoes through the masonry! Three werewolves surround you.');
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
      
      // Scale damage with Strength and Main Hand Weapon power
      // Formula: base (10) + strength * 0.8 + weapon bonus * 1.5
      double rawDmg = 10.0 + (playerStrength.value * 0.8) + (playerWeaponBonus.value * 1.5);
      damage = rawDmg.round();
      
      // Variance
      damage += _random.nextInt(6) - 3; // +/- 3 variance
      if (damage < 5) damage = 5;
      
      // Lane bonus: Melee deals +50% from Front Line
      if (playerLane.value == 'front') {
        damage = (damage * 1.5).round();
      } else {
        // Melee from Back Line deals 30% less damage
        damage = (damage * 0.7).round();
      }
    } else if (skillIndex == 2) {
      skillName = 'Hermetic Firebolt';
      staminaCost = 40;
      
      // Scale magic damage with Intelligence
      // Formula: base (15) + intelligence * 1.8
      double rawDmg = 15.0 + (playerIntelligence.value * 1.8);
      damage = rawDmg.round();
      
      // Variance
      damage += _random.nextInt(8) - 4; // +/- 4 variance
      if (damage < 8) damage = 8;
    }

    if (playerStamina.value < staminaCost) {
      addLog('Too exhausted to use $skillName (Needs $staminaCost Stamina).');
      return false;
    }

    // Deduct costs
    playerAp.value -= 1;
    playerStamina.value -= staminaCost;

    // Apply damage to target
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
      addLog('The ${target.name} collapses into a heap of ashes and dark fur!');
      
      // Auto-target another living enemy
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
    
    // Regain stamina: scales with Constitution!
    // Formula: base (30) + constitution * 1.5
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

    // Apply item effect
    if (item.id == 'c1') { // Essence of Clarity: +50 Stamina
      playerStamina.value = min(playerMaxStamina.value, playerStamina.value + 50);
      addLog('You inhale the Essence of Clarity. Stamina restored (+50).');
      showDamagePopup('player', '+50 STAM');
    } else if (item.id == 'c3') { // Mandrake Root: +30 HP
      playerHp.value = min(playerMaxHp.value, playerHp.value + 30);
      addLog('You consume the Mandrake Root. Wounds close (+30 HP).');
      showDamagePopup('player', '+30 HP');
    } else if (item.id == 'c4') { // Corrupted Soul Gem: +40 HP, +40 Stamina, but -10 Sanity
      playerHp.value = min(playerMaxHp.value, playerHp.value + 40);
      playerStamina.value = min(playerMaxStamina.value, playerStamina.value + 40);
      Get.find<PlayerState>().depleteSanity(10);
      addLog('You shatter the Corrupted Soul Gem. Vitality rushes in (+40 HP/STAM, -10 Sanity).');
      showDamagePopup('player', '+40 HP/STAM');
    } else {
      addLog('This item cannot be used in combat.');
      return;
    }

    // Deduct from inventory
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
    addLog('Turn ended. The werewolves lunge through the darkness...');
    
    // Trigger Enemy Actions
    Future.delayed(const Duration(milliseconds: 1000), () {
      executeEnemyTurnSequence();
    });
  }

  Future<void> executeEnemyTurnSequence() async {
    // Process each enemy sequentially
    for (var enemy in enemies) {
      if (enemy.isDead.value) continue;
      if (!inCombat.value) return;

      // 1. Enemy AI Decision
      // If the enemy is in the back line, they have a 50% chance to move forward, or 50% to cast a ranged attack
      if (enemy.lane.value == 'back') {
        if (_random.nextBool()) {
          enemy.lane.value = 'front';
          addLog('The ${enemy.name} crawls forward to the Front Line.');
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } else {
        // If in front line, they might move back if they are low on health
        if (enemy.hp.value < 15 && _random.nextInt(3) == 0) {
          enemy.lane.value = 'back';
          addLog('The wounded ${enemy.name} retreats to the Back Line.');
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      // 2. Enemy Attacks Player
      if (!inCombat.value) return;
      int baseDmg = 10 + _random.nextInt(8); // 10 to 17

      // Position calculations
      // If player is in the back line, they take 40% less damage from melee enemies in the front
      if (playerLane.value == 'back' && enemy.lane.value == 'front') {
        baseDmg = (baseDmg * 0.6).round();
      }
      
      // If enemy is in the back line, they deal 50% less melee damage
      if (enemy.lane.value == 'back') {
        baseDmg = (baseDmg * 0.5).round();
      }

      // Defense guard calculation
      if (isDefending.value) {
        baseDmg = (baseDmg * 0.5).round();
      }

      playerHp.value -= baseDmg;
      showDamagePopup('player', '-$baseDmg HP');
      
      if (isDefending.value) {
        addLog('The ${enemy.name} swipes at your shield, dealing $baseDmg blocked damage.');
      } else {
        addLog('The ${enemy.name} bites you for $baseDmg physical damage.');
      }

      checkVictoryOrDefeat();
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    // Hand turn back to player
    if (inCombat.value) {
      isPlayerTurn.value = true;
      playerAp.value = 3;
      hasMovedThisTurn.value = false;
      isDefending.value = false;

      // Passive stamina drip
      final staminaDrip = 15;
      playerStamina.value = min(playerMaxStamina.value, playerStamina.value + staminaDrip);

      addLog('Your turn begins. You catch your breath (+15 Stamina).');
      showDamagePopup('player', '+$staminaDrip STAM');
    }
  }

  void checkVictoryOrDefeat() {
    // Check victory
    bool allDead = enemies.every((e) => e.isDead.value);
    if (allDead) {
      inCombat.value = false;
      addLog('VICTORY! You have vanquished the lupine monstrosities.');
      
      // Sync health back to PlayerState and reward XP
      final playerState = Get.find<PlayerState>();
      playerState.vitals.value.currentHp = playerHp.value;
      playerState.vitals.value.currentStamina = playerStamina.value;
      playerState.vitals.refresh();
      playerState.gainXp(50); // Reward 50 XP
      
      Get.snackbar(
        'COMBAT VICTORY',
        'Vanquished the werewolves! Gained 50 XP.',
        backgroundColor: const Color(0xFF162516),
        colorText: const Color(0xFFD4CFC7),
        borderRadius: 0,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    // Check defeat
    if (playerHp.value <= 0) {
      playerHp.value = 0;
      inCombat.value = false;
      addLog('DEFEAT... You fell to the beasts of the Vichally Undercroft.');
      
      // Sync back only to avoid total death loop, or keep 1 hp
      final playerState = Get.find<PlayerState>();
      playerState.vitals.value.currentHp = 1; // revive at 1 HP
      playerState.vitals.refresh();

      Get.snackbar(
        'YOU WERE SLAIN',
        'Defeated in the subterranean dark.',
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
