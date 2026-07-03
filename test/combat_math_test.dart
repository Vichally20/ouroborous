import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/models/skill.dart';
import 'package:ouroboros/states/combat_state.dart';

void main() {
  group('Combat Calculation Tests (Fractional Mitigation Formula)', () {
    late CombatController controller;

    setUp(() {
      Get.testMode = true;
      Get.put(CombatController());
      controller = Get.find<CombatController>();
    });

    tearDown(() {
      Get.reset();
    });

    test('Fractional Mitigation smooth curve: 100 DEF cuts damage by 50%', () {
      const testSkill = CombatSkill(
        id: 'test_heavy',
        name: 'Test Heavy',
        description: 'Test',
        multiplier: 1.0,
      );

      // Raw damage = Weapon (20) + STR*0.5 (10*0.5 = 5) = 25
      // Mitigation at 100 def = 100 / (100 + 100) = 0.5
      // Final hit = 25 * 0.5 = 12.5 -> 13
      final hit = controller.calculateCombatHit(
        weaponDamage: 20,
        attackerStr: 10,
        attackerDex: 10,
        attackerInt: 10,
        attackerSpeed: 10,
        defenderDefense: 100,
        defenderSpeed: 0, // ensure no glance
        skill: testSkill,
        attackerLane: 'front',
        defenderLane: 'front',
        defenderIsDefending: false,
      );

      expect(hit.rawDamage, 25);
      expect(hit.mitigationFactor, closeTo(0.5, 0.001));
      expect(hit.finalDamage, 13);
    });

    test('Skill Multiplier scales damage accurately', () {
      const testSkill = CombatSkill(
        id: 'test_mult',
        name: 'Test Mult',
        description: 'Test',
        multiplier: 1.5,
      );

      // Raw damage = 20 + 5 = 25
      // Skill damage = 25 * 1.5 = 37.5 -> 38
      // Mitigation at 50 def = 100 / (100 + 50) = 2/3 ≈ 0.6667
      // Final = 37.5 * 0.6667 = 25
      final hit = controller.calculateCombatHit(
        weaponDamage: 20,
        attackerStr: 10,
        attackerDex: 10,
        attackerInt: 10,
        attackerSpeed: 10,
        defenderDefense: 50,
        defenderSpeed: 0,
        skill: testSkill,
        attackerLane: 'front',
        defenderLane: 'front',
        defenderIsDefending: false,
      );

      expect(hit.skillDamage, 38);
      expect(hit.finalDamage, 25);
    });

    test('Armor Ignore bypasses defender defense completely', () {
      const testSkill = CombatSkill(
        id: 'test_ignore',
        name: 'Test Ignore',
        description: 'Test',
        multiplier: 1.0,
        ignoresArmor: true,
      );

      final hit = controller.calculateCombatHit(
        weaponDamage: 20,
        attackerStr: 10,
        attackerDex: 10,
        attackerInt: 10,
        attackerSpeed: 10,
        defenderDefense: 200,
        defenderSpeed: 0,
        skill: testSkill,
        attackerLane: 'front',
        defenderLane: 'front',
        defenderIsDefending: false,
      );

      expect(hit.mitigationFactor, 1.0);
      expect(hit.finalDamage, 25);
    });

    test('Post-hit perks apply Bleed, Poison, and Lifesteal', () {
      const testSkill = CombatSkill(
        id: 'test_perk',
        name: 'Test Perk',
        description: 'Test',
        multiplier: 1.0,
      );

      final hit = controller.calculateCombatHit(
        weaponDamage: 40,
        attackerStr: 20,
        attackerDex: 10,
        attackerInt: 10,
        attackerSpeed: 10,
        defenderDefense: 0,
        defenderSpeed: 0,
        skill: testSkill,
        attackerLane: 'front',
        defenderLane: 'front',
        defenderIsDefending: false,
        attackerPerks: ['bleed', 'poison', 'lifesteal'],
      );

      expect(hit.bleedApplied, 2);
      expect(hit.poisonApplied, 2);
      expect(hit.lifestealHeal, greaterThan(0));
    });
  });
}
