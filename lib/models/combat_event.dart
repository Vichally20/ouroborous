/// Data payload describing a single combat event for the UI animation layer.
/// The controller populates this; the UI reads it to decide what to animate.
class CombatEvent {
  final String skillName;
  final String weaponName;
  final String targetId;
  final List<int> damageHits; // e.g. [15] single, [8, 7] double slash
  final List<String> perks; // e.g. ["+4 Bleed"] — ready for perk system
  final bool isCritical;
  final bool isPlayerAction; // true = player attacked, false = enemy attacked player

  const CombatEvent({
    required this.skillName,
    required this.weaponName,
    required this.targetId,
    required this.damageHits,
    this.perks = const [],
    this.isCritical = false,
    this.isPlayerAction = true,
  });

  int get totalDamage => damageHits.fold(0, (sum, hit) => sum + hit);

  String get formattedWeaponSkill =>
      '${weaponName.toUpperCase()} ⟫ $skillName';
}
