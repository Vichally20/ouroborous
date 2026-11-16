import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/models/combat_models.dart';
import 'package:ouroboros/models/item.dart';
import 'package:ouroboros/states/combat_state.dart';
import 'package:ouroboros/states/inventory_state.dart';
import 'package:ouroboros/states/player_state.dart';
import 'package:ouroboros/states/settings_state.dart';
import 'package:ouroboros/states/town_state.dart';

EnemyTemplate _tmpl({required double aggression, double range = 0.0}) => EnemyTemplate(
      id: 'wolf',
      name: 'Test Wolf',
      imageAsset: 'assets/images/enemies/werewolf_feral.png',
      maxHp: 400,
      maxStamina: 200,
      maxAp: 1,
      strength: 12,
      defense: 3,
      speed: 1,
      aiProfile: AiProfile(aggression: aggression, selfPreservation: 0, preferredRange: range),
      availableSkills: const ['strike'],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CombatController combat;

  setUp(() {
    Get.testMode = true;
    combat = Get.put(CombatController());
  });
  tearDown(Get.reset);

  void startVs(ActiveEnemy enemy) {
    combat.startSandboxCombat(
      heroName: 'Tester',
      heroMaxHp: 500,
      heroMaxStamina: 100,
      heroStrength: 12,
      heroIntelligence: 10,
      heroConstitution: 10,
      weaponName: 'Sword',
      weaponBonus: 14,
      weaponRange: WeaponRange.melee,
      enemy: enemy,
    );
  }

  group('a battle ends once', () {
    test('defeat is announced once however often the outcome is checked', () {
      final wolf = ActiveEnemy(instanceId: 'w1', template: _tmpl(aggression: 1.0), initialHp: 400, initialStamina: 200, initialLane: 'front');
      startVs(wolf);
      combat.playerHp.value = 0;
      for (var i = 0; i < 3; i++) {
        combat.checkVictoryOrDefeat();
      }
      expect(combat.isResolved, isTrue);
      expect(combat.combatLogs.where((l) => l.contains('DEFEAT')).length, 1);

      // A retry starts a fresh battle that can end again.
      startVs(ActiveEnemy(instanceId: 'w2', template: _tmpl(aggression: 1.0), initialHp: 400, initialStamina: 200, initialLane: 'front'));
      expect(combat.isResolved, isFalse);
    });

    test('victory pays XP and interest once', () {
      final player = Get.put(PlayerState());
      Get.put(InventoryState());
      final town = Get.put(TownState());
      town.deposit(1000);
      final wolf = ActiveEnemy(instanceId: 'w1', template: _tmpl(aggression: 1.0), initialHp: 400, initialStamina: 200, initialLane: 'front');
      startVs(wolf);
      combat.isSandbox.value = false; // judge it as a story battle
      wolf.hp.value = 0;
      for (var i = 0; i < 3; i++) {
        combat.checkVictoryOrDefeat();
      }
      expect(player.currentXp.value, 50);
      expect(town.bankedCrowns.value, 1050);
      expect(combat.combatLogs.where((l) => l.startsWith('VICTORY')).length, 1);
    });
  });

  test('pacing defaults to 450ms between actions', () {
    expect(SettingsState().attackDelay.value, 0.45);
  });

  test('turn order and intents are set when your turn starts', () {
    final wolf = ActiveEnemy(instanceId: 'w1', template: _tmpl(aggression: 1.0), initialHp: 400, initialStamina: 200, initialLane: 'front');
    startVs(wolf);

    expect(combat.isPlayerTurn.value, isTrue);
    expect(combat.turnOrder, ['player', 'w1']);
    expect(combat.currentActorId.value, 'player');
    expect(combat.round.value, 1);

    final intent = wolf.intent.value;
    expect(intent, isNotNull);
    expect(intent!.kind, IntentKind.attack);
    expect(intent.targetId, 'player');
    expect(intent.estimatedDamage, greaterThan(0));
  });

  test('the enemy follows its intent, and the estimate matches the hit', () async {
    final wolf = ActiveEnemy(instanceId: 'w1', template: _tmpl(aggression: 1.0), initialHp: 400, initialStamina: 200, initialLane: 'front');
    startVs(wolf);
    final estimate = wolf.intent.value!.estimatedDamage;
    final hpBefore = combat.playerHp.value;

    combat.endPlayerTurn();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(hpBefore - combat.playerHp.value, estimate);
    expect(combat.lastCombatEvent.value?.attackerId, 'w1');
  });

  test('bracing lowers the shown intent damage', () {
    final wolf = ActiveEnemy(instanceId: 'w1', template: _tmpl(aggression: 1.0), initialHp: 400, initialStamina: 200, initialLane: 'front');
    startVs(wolf);
    final open = wolf.intent.value!.estimatedDamage;
    combat.playerDefend();
    expect(wolf.intent.value!.estimatedDamage, lessThan(open));
  });

  test('moving changes reach: a back-line brawler can\'t hit you on your back line', () {
    final wolf = ActiveEnemy(instanceId: 'w1', template: _tmpl(aggression: 1.0), initialHp: 400, initialStamina: 200, initialLane: 'back');
    startVs(wolf);
    // Player starts on the back line; a melee wolf on its back line must close in first.
    expect(wolf.intent.value!.kind, isNot(IntentKind.attack));
    expect(combat.skillReaches(0, wolf), isFalse, reason: 'your melee can\'t reach their back line from yours');

    combat.playerMove(); // to the front line
    expect(combat.skillReaches(0, wolf), isTrue);
  });

  test('the hand preview matches the damage actually dealt', () {
    final wolf = ActiveEnemy(instanceId: 'w1', template: _tmpl(aggression: 1.0), initialHp: 400, initialStamina: 200, initialLane: 'front');
    startVs(wolf);
    final (normal, crit) = combat.previewSkillDamage(0, wolf)!;
    expect(crit, greaterThan(normal));

    final before = wolf.hp.value;
    expect(combat.playerAttack(0), isTrue);
    expect(before - wolf.hp.value, normal);
    expect(combat.lastCombatEvent.value?.attackerId, 'player');
  });
}
