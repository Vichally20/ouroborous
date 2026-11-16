import 'hero_character.dart';
import 'item.dart';
import 'talent_node.dart';

/// The numbers a hero brings into battle, from attributes, equipment and talents.
/// Combat and the Persona screen both read this, so what the player sees is what is used.
class HeroCombatStats {
  final int strength;
  final int dexterity;
  final int intelligence;
  final int constitution;
  final int speed;

  /// Armour, including talents. Used as the defender's defense in battle.
  final int defense;
  final int weaponDamage;
  final WeaponRange weaponRange;
  final bool twoHanded;
  final String weaponName;
  final List<String> weaponPerks;
  final TalentEffect talents;

  const HeroCombatStats({
    required this.strength,
    required this.dexterity,
    required this.intelligence,
    required this.constitution,
    required this.speed,
    required this.defense,
    required this.weaponDamage,
    required this.weaponRange,
    required this.twoHanded,
    required this.weaponName,
    required this.weaponPerks,
    required this.talents,
  });

  /// Base weapon damage when nothing (or a 0-bonus item) is in the main hand.
  static const unarmedDamage = 12;

  /// Defense used when no apparel is worn.
  static const unarmouredDefense = 5;

  factory HeroCombatStats.of(HeroCharacter hero) {
    final t = hero.talentEffect;
    final a = hero.attributes;
    final l = hero.loadout;

    int armour = 0;
    for (final item in l.equipped) {
      if (item.category == ItemCategory.apparel) armour += item.power;
    }
    final baseDefense = armour > 0 ? armour : unarmouredDefense;

    final main = l.mainHand;
    final baseSpeed = 10 + (a.dexterity * 0.5).round();

    return HeroCombatStats(
      strength: (a.strength * (1 + t.strengthPct)).round(),
      dexterity: a.dexterity,
      intelligence: a.intelligence,
      constitution: a.constitution,
      speed: (baseSpeed * (1 + t.speedPct)).round(),
      defense: baseDefense + t.defenseFlat,
      weaponDamage: (main != null && main.power > 0) ? main.power : unarmedDamage,
      weaponRange: main?.weaponRange ?? WeaponRange.melee,
      twoHanded: main?.twoHanded ?? false,
      weaponName: main?.displayName ?? 'Unarmed',
      weaponPerks: main?.perks ?? const [],
      talents: t,
    );
  }

  /// A basic physical strike (1.0x skill, front line) before the target's armour:
  /// (normal hit, critical hit). Mirrors CombatController.calculateCombatHit.
  (int, int) strikeDamage() {
    final raw = (weaponDamage + strength * 0.5).round();
    var mult = 1 + talents.damageDealtPct;
    if (twoHanded) mult += talents.twoHandedDamagePct;
    final hit = raw * mult;
    return (hit.round(), (hit * 1.5).round());
  }
}
