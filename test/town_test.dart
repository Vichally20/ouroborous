import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/models/combat_stats.dart';
import 'package:ouroboros/models/item.dart';
import 'package:ouroboros/states/inventory_state.dart';
import 'package:ouroboros/states/player_state.dart';
import 'package:ouroboros/states/town_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerState player;
  late InventoryState inv;
  late TownState town;

  setUp(() {
    Get.testMode = true;
    inv = Get.put(InventoryState());
    player = Get.put(PlayerState());
    town = Get.put(TownState());
  });
  tearDown(Get.reset);

  ArtifactItem packItem(String id) => inv.ledger.firstWhere((i) => i.id == id);

  group('Forge', () {
    test('tempering the worn claymore raises battle damage and costs crowns', () {
      final claymore = player.activeHero.loadout.mainHand!;
      final before = HeroCombatStats.of(player.activeHero).weaponDamage;
      final purse = town.purse;
      final cost = town.temperCost(claymore)!;
      expect(cost, 240, reason: 'relic: 120 x 2');

      expect(town.temper(claymore, equipped: true), isNull);

      final tempered = player.activeHero.loadout.mainHand!;
      expect(tempered.temper, 1);
      expect(tempered.displayName, 'Blackiron Claymore +1');
      expect(tempered.twoHanded, isTrue);
      expect(HeroCombatStats.of(player.activeHero).weaponDamage, before + 3);
      expect(town.purse, purse - cost);
      expect(inv.ledger.where((i) => i.baseId == claymore.baseId), isEmpty, reason: 'old copy not dumped in the pack');
    });

    test('carried gear is tempered in the pack', () {
      final greaves = packItem('ap2');
      expect(town.temper(greaves, equipped: false), isNull);
      expect(inv.countOf('ap2'), 0);
      final t = packItem('ap2@t1');
      expect(t.power, greaves.statBonus + 2);
      expect(town.temper(t, equipped: false), isNull);
      expect(packItem('ap2@t2').temper, 2);
    });

    test('three levels at most, and no credit', () {
      var item = packItem('ap3');
      for (var t = 0; t < ArtifactItem.maxTemper; t++) {
        expect(town.temper(item, equipped: false), isNull);
        item = packItem('ap3@t${t + 1}');
      }
      expect(town.temperCost(item), isNull);
      expect(town.temper(item, equipped: false), contains('already tempered'));

      inv.removeStack(TownState.crownsId);
      expect(town.temper(packItem('ap2'), equipped: false), contains('wants'));
      expect(inv.countOf('ap2'), 1, reason: 'nothing changed');
    });

    test('the apprentice buys pack gear only', () {
      expect(town.sellableGear.map((i) => i.id), containsAll(['ap2', 'ap3']));
      expect(town.sellableGear.any((i) => i.id == player.activeHero.loadout.mainHand!.id), isFalse);
      final purse = town.purse;
      final greaves = packItem('ap2');
      expect(town.sell(greaves), isNull);
      expect(inv.countOf('ap2'), 0);
      expect(town.purse, purse + town.sellPrice(greaves));
    });
  });

  group('Counting House', () {
    test('deposit and withdraw move crowns between purse and vault', () {
      final purse = town.purse;
      expect(town.deposit(1000), isNull);
      expect(town.purse, purse - 1000);
      expect(town.bankedCrowns.value, 1000);
      expect(town.withdraw(2000), contains('only 1000'));
      expect(town.withdraw(400), isNull);
      expect(town.purse, purse - 600);
      expect(town.deposit(purse * 2), isNotNull);
    });

    test('banked crowns earn interest; fleeing drops a tenth of the purse', () {
      town.deposit(1000);
      expect(town.accrueInterest(), 50);
      expect(town.bankedCrowns.value, 1050);

      final purse = town.purse;
      expect(town.dropPurseOnFlee(), purse ~/ 10);
      expect(town.purse, purse - purse ~/ 10);
      expect(town.bankedCrowns.value, 1050, reason: 'vault untouched');
    });

    test('drachma change into crowns', () {
      final purse = town.purse, d = town.drachma;
      expect(town.exchangeDrachma(10), isNull);
      expect(town.drachma, d - 10);
      expect(town.purse, purse + 10 * TownState.drachmaRate);
      expect(town.exchangeDrachma(d), contains('only'));
    });

    test('withdrawing with an empty purse recreates the crowns stack', () {
      town.deposit(town.purse);
      expect(inv.countOf(TownState.crownsId), 0);
      expect(town.withdraw(10), isNull);
      expect(town.purse, 10);
    });
  });

  group('Drowned Lantern Inn', () {
    void wound() {
      for (final h in player.heroes) {
        h.vitals
          ..currentHp = 10
          ..currentStamina = 5
          ..currentMana = 0
          ..currentSanity = 40;
      }
    }

    test('a fresh party is turned away without paying', () {
      expect(town.partyFresh, isTrue);
      final purse = town.purse;
      expect(town.rest(InnRoom.cot), contains('already rested'));
      expect(town.purse, purse);
    });

    test('a cot heals the whole party and calms a little', () {
      wound();
      final purse = town.purse;
      expect(town.rest(InnRoom.cot), isNull);
      expect(town.purse, purse - InnRoom.cot.price);
      for (final h in player.heroes) {
        expect(h.vitals.currentHp, h.vitals.maxHp, reason: h.name);
        expect(h.vitals.currentStamina, h.vitals.maxStamina);
        expect(h.vitals.currentSanity, 40 + InnRoom.cotSanity);
        expect(h.vitals.currentMana, 0, reason: 'a cot does not restore mana');
      }
      expect(player.vitals.value.currentHp, player.activeHero.vitals.maxHp, reason: 'HUD vitals follow');
    });

    test('a private room restores everything', () {
      wound();
      expect(town.rest(InnRoom.privateRoom), isNull);
      expect(town.partyFresh, isTrue);
    });

    test('no bed on credit', () {
      wound();
      inv.removeStack(TownState.crownsId);
      expect(town.rest(InnRoom.cot), contains('carry 0'));
      expect(player.activeHero.vitals.currentHp, 10);
    });

    test('the bar serves the active hero only', () {
      wound();
      final other = player.heroes.firstWhere((h) => h != player.activeHero);
      final purse = town.purse;
      expect(town.drink(InnFare.stew), isNull);
      expect(player.activeHero.vitals.currentHp, 40);
      expect(player.activeHero.vitals.currentStamina, 25);
      expect(other.vitals.currentHp, 10);
      expect(town.purse, purse - InnFare.stew.price);

      expect(town.drink(InnFare.ale), isNull);
      expect(player.activeHero.vitals.currentSanity, 55);

      player.activeHero.vitals.currentSanity = player.activeHero.vitals.maxSanity;
      expect(town.drink(InnFare.ale), contains('another mug'));
    });
  });
}
