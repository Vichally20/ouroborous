import 'package:get/get.dart';

import '../models/item.dart';
import 'inventory_state.dart';
import 'player_state.dart';

/// High Street services in Bowerstone: the Ashen Anvil Forge (temper and sell
/// gear) and the Serpent-Seal Counting House (bank crowns, change drachma).
///
/// Every action returns null on success or a line explaining why it can't happen,
/// so the UI can show it and tests can check it without a screen.
class TownState extends GetxController {
  static const crownsId = 'cur1';
  static const drachmaId = 'cur2';

  /// Crowns paid per Ancient Drachma at the Vault Warden's table.
  static const drachmaRate = 10;

  /// Interest on banked crowns, credited after each won battle (story battles only).
  static const interestRate = 0.05;

  /// Share of the carried purse dropped when fleeing a story battle.
  static const fleeLossRate = 0.10;

  /// Crowns held in the Counting House vault, out of harm's way.
  final bankedCrowns = 0.obs;

  InventoryState get _inv => Get.find<InventoryState>();
  PlayerState get _player => Get.find<PlayerState>();

  /// Crowns carried in the inventory.
  int get purse => _inv.countOf(crownsId);
  int get drachma => _inv.countOf(drachmaId);

  bool _spend(int crowns) => crowns <= 0 || _inv.removeItem(crownsId, count: crowns);

  /// Adds (or, when negative, takes up to what you carry of) [delta] crowns. Used by story effects.
  void addCrowns(int delta) {
    if (delta > 0) {
      _earn(delta);
    } else if (delta < 0) {
      _spend(-delta > purse ? purse : -delta);
    }
  }

  void _earn(int crowns) {
    if (crowns <= 0) return;
    final existing = _inv.ledger.firstWhereOrNull((i) => i.id == crownsId);
    _inv.addItem(existing ?? _crowns, count: crowns);
  }

  static const _crowns = ArtifactItem(
    id: crownsId,
    name: 'Ouroboros Crowns',
    description: 'Ancient royal coinage bearing the serpent seal.',
    category: ItemCategory.currency,
    rarity: ItemRarity.relic,
    weight: 0,
  );

  // ─── Forge ────────────────────────────────────────────────────────────────

  static const _rarityMult = {
    ItemRarity.common: 1.0,
    ItemRarity.unpolished: 1.2,
    ItemRarity.clinical: 1.5,
    ItemRarity.relic: 2.0,
    ItemRarity.vitruvian: 3.0,
  };
  static const _temperBase = [120, 300, 650];
  static const _sellBase = {
    ItemRarity.common: 40,
    ItemRarity.unpolished: 70,
    ItemRarity.clinical: 120,
    ItemRarity.relic: 250,
    ItemRarity.vitruvian: 500,
  };

  static bool isForgeable(ArtifactItem item) =>
      item.category == ItemCategory.weapon || item.category == ItemCategory.apparel;

  /// Crowns to raise [item] one temper level, or null when it's already at the maximum.
  int? temperCost(ArtifactItem item) {
    if (!isForgeable(item) || item.temper >= ArtifactItem.maxTemper) return null;
    return (_temperBase[item.temper] * (_rarityMult[item.rarity] ?? 1)).round();
  }

  /// What the apprentice pays for [item]: a rarity price plus a third of its tempering.
  int sellPrice(ArtifactItem item) {
    var spent = 0;
    for (var t = 0; t < item.temper && t < _temperBase.length; t++) {
      spent += (_temperBase[t] * (_rarityMult[item.rarity] ?? 1)).round();
    }
    return (_sellBase[item.rarity] ?? 40) + spent ~/ 3;
  }

  /// Gear the forge can work on: what the active hero wears first, then the pack.
  List<({ArtifactItem item, bool equipped})> get forgeableGear => [
        for (final i in _player.activeHero.loadout.equipped)
          if (isForgeable(i)) (item: i, equipped: true),
        for (final i in _inv.ledger)
          if (isForgeable(i)) (item: i, equipped: false),
      ];

  /// Gear the apprentice will buy: weapons and apparel in the pack (not worn).
  List<ArtifactItem> get sellableGear => _inv.ledger.where(isForgeable).toList();

  /// Tempers one [item] by a level, worn or carried.
  String? temper(ArtifactItem item, {required bool equipped}) {
    final cost = temperCost(item);
    if (cost == null) return '${item.name} is already tempered as far as steel will go.';
    if (purse < cost) return 'The smith wants $cost crowns. You carry $purse.';

    final upgraded = item.copyWith(count: 1, temper: item.temper + 1, id: '${item.baseId}@t${item.temper + 1}');
    if (equipped) {
      final loadout = _player.activeHero.loadout;
      if (!loadout.equipped.any((e) => e.id == item.id)) return '${item.name} is no longer worn.';
      _spend(cost);
      // Re-equipping into the same slot displaces only the old copy.
      for (final d in loadout.equip(upgraded)) {
        if (d.id != item.id) _inv.addItem(d, count: 1);
      }
      _player.loadout.refresh();
      _player.heroes.refresh();
    } else {
      if (_inv.countOf(item.id) < 1) return '${item.name} is no longer in your pack.';
      _spend(cost);
      _inv.removeItem(item.id);
      _inv.addItem(upgraded, count: 1);
    }
    return null;
  }

  /// Sells one [item] from the pack to the apprentice.
  String? sell(ArtifactItem item) {
    if (!isForgeable(item)) return 'The apprentice only buys arms and armour.';
    if (!_inv.removeItem(item.id)) return '${item.name} is no longer in your pack.';
    _earn(sellPrice(item));
    return null;
  }

  // ─── Counting House ───────────────────────────────────────────────────────

  String? deposit(int crowns) {
    if (crowns <= 0) return 'Name a sum first.';
    if (purse < crowns) return 'You carry only $purse crowns.';
    _spend(crowns);
    bankedCrowns.value += crowns;
    return null;
  }

  String? withdraw(int crowns) {
    if (crowns <= 0) return 'Name a sum first.';
    if (bankedCrowns.value < crowns) return 'The vault holds only ${bankedCrowns.value} crowns.';
    bankedCrowns.value -= crowns;
    _earn(crowns);
    return null;
  }

  /// Interest after a won battle. Returns the crowns credited to the vault.
  int accrueInterest() {
    final gained = (bankedCrowns.value * interestRate).floor();
    bankedCrowns.value += gained;
    return gained;
  }

  /// Crowns lost from the carried purse when fleeing. Banked crowns are safe.
  int dropPurseOnFlee() {
    final lost = (purse * fleeLossRate).floor();
    _spend(lost);
    return lost;
  }

  /// Changes [count] Ancient Drachma into crowns at [drachmaRate].
  String? exchangeDrachma(int count) {
    if (count <= 0) return 'Name a sum first.';
    if (drachma < count) return 'You carry only $drachma drachma.';
    _inv.removeItem(drachmaId, count: count);
    _earn(count * drachmaRate);
    return null;
  }

  // ─── Drowned Lantern Inn ──────────────────────────────────────────────────

  /// True when every hero in the party is already at full health, stamina,
  /// mana and sanity, so a bed would buy nothing.
  bool get partyFresh => _player.heroes.every((h) {
        final v = h.vitals;
        return v.currentHp >= v.maxHp &&
            v.currentStamina >= v.maxStamina &&
            v.currentMana >= v.maxMana &&
            v.currentSanity >= v.maxSanity;
      });

  /// Takes a bed for the night. Heals every hero in the party, not just the active one.
  String? rest(InnRoom room) {
    if (partyFresh) return 'Your party is already rested. Marrow won\'t take crowns for nothing.';
    if (purse < room.price) return 'A ${room.label.toLowerCase()} is ${room.price} crowns. You carry $purse.';
    _spend(room.price);
    for (final h in _player.heroes) {
      final v = h.vitals;
      v.currentHp = v.maxHp;
      v.currentStamina = v.maxStamina;
      if (room == InnRoom.privateRoom) {
        v.currentMana = v.maxMana;
        v.currentSanity = v.maxSanity;
      } else {
        v.currentSanity = (v.currentSanity + InnRoom.cotSanity).clamp(0, v.maxSanity);
      }
    }
    _player.vitals.refresh();
    _player.heroes.refresh();
    return null;
  }

  /// Buys [fare] at the bar for the active hero.
  String? drink(InnFare fare) {
    final v = _player.activeHero.vitals;
    final helps = (fare.hp > 0 && v.currentHp < v.maxHp) ||
        (fare.stamina > 0 && v.currentStamina < v.maxStamina) ||
        (fare.sanity > 0 && v.currentSanity < v.maxSanity);
    if (!helps) return 'You couldn\'t manage another ${fare.unit}.';
    if (purse < fare.price) return 'Tess wants ${fare.price} crowns. You carry $purse.';
    _spend(fare.price);
    v.currentHp = (v.currentHp + fare.hp).clamp(0, v.maxHp);
    v.currentStamina = (v.currentStamina + fare.stamina).clamp(0, v.maxStamina);
    v.currentSanity = (v.currentSanity + fare.sanity).clamp(0, v.maxSanity);
    _player.vitals.refresh();
    _player.heroes.refresh();
    return null;
  }
}

/// Beds at the Drowned Lantern. Both heal the whole party.
enum InnRoom {
  cot('Common-room cot', 25, 'Full health and stamina for the party, and +$cotSanity sanity.'),
  privateRoom('Private room', 120, 'Everyone wakes whole: health, stamina, mana and sanity.');

  /// Sanity a night on a straw pallet gives back.
  static const cotSanity = 15;

  final String label;
  final int price;
  final String blurb;
  const InnRoom(this.label, this.price, this.blurb);
}

/// What Barmaid Tess serves. Each helps the active hero only.
enum InnFare {
  ale('Mug of black ale', 'mug', 8, sanity: 15),
  stew('Bowl of eel stew', 'bowl', 15, hp: 30, stamina: 20);

  final String label;
  final String unit;
  final int price;
  final int hp;
  final int stamina;
  final int sanity;
  const InnFare(this.label, this.unit, this.price, {this.hp = 0, this.stamina = 0, this.sanity = 0});

  String get summary => [
        if (hp > 0) '+$hp HP',
        if (stamina > 0) '+$stamina STA',
        if (sanity > 0) '+$sanity SAN',
      ].join(' · ');
}
