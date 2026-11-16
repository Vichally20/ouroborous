import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/models/combat_stats.dart';
import 'package:ouroboros/models/item.dart';
import 'package:ouroboros/models/item_catalog.dart';
import 'package:ouroboros/models/loadout.dart';
import 'package:ouroboros/models/skill.dart';
import 'package:ouroboros/models/talent_node.dart';
import 'package:ouroboros/states/combat_state.dart';
import 'package:ouroboros/states/inventory_state.dart';
import 'package:ouroboros/states/player_state.dart';

const _strike = CombatSkill(id: 't', name: 'Test', description: 'Test', multiplier: 1.0);

void main() {
  test('every warrior talent has its medallion icon on disk', () {
    for (final n in TalentTree.warrior.nodes) {
      expect(n.iconAsset, isNotNull, reason: n.id);
      expect(File(n.iconAsset!).existsSync(), isTrue, reason: n.iconAsset);
    }
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerState player;
  late InventoryState inventory;

  setUp(() {
    Get.testMode = true;
    inventory = Get.put(InventoryState());
    player = Get.put(PlayerState());
  });

  tearDown(Get.reset);

  group('Talents', () {
    test('Aleph starts with only the tier I root and no points', () {
      final aleph = player.heroes.first;
      expect(aleph.unlockedTalents, {'root'});
      expect(player.talentPointsFor(aleph), 0);
      expect(player.canUnlockTalent('branchA'), isFalse);
    });

    test('a level-up grants one point, spent only downward from owned nodes', () {
      player.gainXp(100); // level 2
      expect(player.talentPointsFor(player.activeHero), 1);

      // Tier III and the capstone are out of reach until a parent is owned.
      expect(player.canUnlockTalent('nodeC2'), isFalse);
      expect(player.canUnlockTalent('capstone'), isFalse);
      expect(player.canUnlockTalent('root'), isFalse, reason: 'already owned');

      expect(player.unlockTalent('branchC'), isTrue);
      expect(player.talentPointsFor(player.activeHero), 0);
      expect(player.unlockTalent('nodeC2'), isFalse, reason: 'no points left');

      player.gainXp(150); // level 3
      expect(player.canUnlockTalent('nodeC2'), isTrue);
      expect(player.canUnlockTalent('nodeA1'), isFalse, reason: 'Juggernaut not owned');
    });

    test('intersection nodes open from either parent', () {
      const tree = TalentTree.warrior;
      expect(tree.isReachable('nodeA2', {'root', 'branchB'}), isTrue);
      expect(tree.isReachable('capstone', {'root', 'branchC', 'nodeC1'}), isTrue);
      expect(tree.isReachable('capstone', {'root', 'branchC'}), isFalse);
    });

    test('owned talents change the hero\'s battle stats', () {
      final aleph = player.heroes.first;
      final stats = HeroCombatStats.of(aleph);
      // Iron Fundamentals: +10% Strength (16 -> 18), +2 armour (robes 14 -> 16).
      expect(stats.strength, 18);
      expect(stats.defense, 16);
      expect(stats.twoHanded, isTrue, reason: 'the Blackiron Claymore is two-handed');
    });
  });

  group('Talents in combat', () {
    late CombatController combat;
    setUp(() => combat = Get.put(CombatController()));

    int hit({TalentEffect att = TalentEffect.none, TalentEffect def = TalentEffect.none,
        bool twoHanded = false, bool exec = false, int defense = 0, bool defending = false}) {
      return combat
          .calculateCombatHit(
            weaponDamage: 20,
            attackerStr: 20,
            attackerDex: 10,
            attackerInt: 10,
            attackerSpeed: 10,
            defenderDefense: defense,
            defenderSpeed: 0,
            skill: _strike,
            attackerLane: 'front',
            defenderLane: 'front',
            defenderIsDefending: defending,
            attackerTalents: att,
            defenderTalents: def,
            attackerTwoHanded: twoHanded,
            targetExecutable: exec,
          )
          .finalDamage;
    }

    test('damage dealt, damage taken, two-handed and execute multiply the hit', () {
      expect(hit(), 30); // 20 + 20*0.5
      expect(hit(att: const TalentEffect(damageDealtPct: 0.15)), 35);
      expect(hit(def: const TalentEffect(damageTakenPct: -0.15)), 26);
      expect(hit(att: const TalentEffect(twoHandedDamagePct: 0.25), twoHanded: true), 38);
      expect(hit(att: const TalentEffect(twoHandedDamagePct: 0.25)), 30, reason: 'no bonus one-handed');
      expect(hit(att: const TalentEffect(executeMultiplier: 3.0), exec: true), 90);
    });

    test('armour ignore and guard bonus change mitigation', () {
      expect(hit(defense: 100), 15);
      expect(hit(defense: 100, att: const TalentEffect(armorIgnore: 0.25)), 17); // 30 * 100/175
      expect(hit(defending: true), 15);
      expect(hit(defending: true, def: const TalentEffect(guardBonus: 0.10)), 12);
    });

    test('critical hits add talent bleed', () {
      final r = combat.calculateCombatHit(
        weaponDamage: 20, attackerStr: 20, attackerDex: 10, attackerInt: 10, attackerSpeed: 10,
        defenderDefense: 0, defenderSpeed: 0, skill: _strike, attackerLane: 'front', defenderLane: 'front',
        defenderIsDefending: false, attackerTalents: const TalentEffect(bleedOnCrit: 3), forceCrit: true,
      );
      expect(r.isCrit, isTrue);
      expect(r.bleedApplied, 3);
    });
  });

  group('Inventory', () {
    test('stacks add, remove one at a time, and weigh by count', () {
      final essence = inventory.ledger.firstWhere((i) => i.id == 'c1');
      expect(essence.count, 4);
      inventory.addItem(essence, count: 2);
      expect(inventory.countOf('c1'), 6);
      expect(inventory.removeItem('c1'), isTrue);
      expect(inventory.countOf('c1'), 5);
      expect(inventory.removeItem('c1', count: 9), isFalse);
      inventory.removeItem('c1', count: 5);
      expect(inventory.countOf('c1'), 0);
      expect(inventory.ledger.any((i) => i.id == 'c1'), isFalse);

      final before = inventory.totalInventoryWeight;
      inventory.addItem(const ArtifactItem(
          id: 'x', name: 'Rock', description: '', category: ItemCategory.miscellaneous,
          rarity: ItemRarity.common, weight: 2.0), count: 3);
      expect(inventory.totalInventoryWeight, closeTo(before + 6.0, 1e-9));
    });

    test('equipped starting gear is not also in the inventory', () {
      for (final id in ['w1', 'w2', 'w3', 'ap1']) {
        expect(inventory.countOf(id), 0, reason: '$id is worn by a hero');
      }
    });

    test('a consumable outside battle applies its effect and uses one', () {
      player.vitals.value.currentHp = 50;
      final root = inventory.ledger.firstWhere((i) => i.id == 'c3');
      expect(player.useConsumable(root), isNotNull);
      expect(player.vitals.value.currentHp, 80);
      expect(inventory.countOf('c3'), 1);
    });
  });

  group('Loadout', () {
    test('equip moves the item out of the inventory and returns the old one', () {
      final greaves = inventory.ledger.firstWhere((i) => i.id == 'ap2');
      expect(player.equipArtifact(greaves), isTrue);
      expect(player.activeHero.loadout.leg?.id, 'ap2');
      expect(inventory.countOf('ap2'), 0);

      final removed = player.unequipArtifact(AnatomicalSlot.leg);
      expect(removed?.id, 'ap2');
      expect(player.activeHero.loadout.leg, isNull);
      expect(inventory.countOf('ap2'), 1);
    });

    test('items not in the inventory cannot be equipped', () {
      const ghost = ArtifactItem(
          id: 'nope', name: 'Ghost Blade', description: '', category: ItemCategory.weapon,
          rarity: ItemRarity.common, weight: 1, equipSlot: AnatomicalSlot.mainHand, statBonus: 99);
      expect(player.equipArtifact(ghost), isFalse);
    });

    test('a two-handed weapon pushes out the off-hand, and vice versa', () {
      const claymore = ArtifactItem(
          id: 'big', name: 'Big', description: '', category: ItemCategory.weapon, rarity: ItemRarity.common,
          weight: 8, equipSlot: AnatomicalSlot.mainHand, twoHanded: true);
      const dagger = ArtifactItem(
          id: 'small', name: 'Small', description: '', category: ItemCategory.weapon, rarity: ItemRarity.common,
          weight: 1, equipSlot: AnatomicalSlot.secondaryHand);
      final l = AnatomicalLoadout(secondaryHand: dagger);
      expect(l.equip(claymore).map((i) => i.id), ['small']);
      expect(l.secondaryHand, isNull);
      expect(l.equip(dagger).map((i) => i.id), ['big']);
      expect(l.mainHand, isNull);
    });
  });

  group('Story loot', () {
    test('callouts become real items, split on +', () {
      final items = ItemCatalog.fromLootCallout(
          'Acquired: Sealed Amphitheater Letter + Crypt Tunnel Map', fallbackIdPrefix: 'loot_n');
      expect(items.map((i) => i.id), ['q_amphitheater_letter', 'q_crypt_map']);

      final falchion = ItemCatalog.fromLootCallout('Loot Uncovered: Rusted Falchion', fallbackIdPrefix: 'x').single;
      expect(falchion.equipSlot, AnatomicalSlot.mainHand);

      final vessel = ItemCatalog.fromLootCallout('Acquired: The Pulsing Vessel (Quest Item)', fallbackIdPrefix: 'x').single;
      expect(vessel.id, 'q_pulsing_vessel');
    });
  });
}
