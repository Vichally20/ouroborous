import 'character_class.dart';
import 'attributes.dart';
import 'loadout.dart';
import 'talent_node.dart';
import 'vitals.dart';
import 'combat_models.dart';
import 'hero_portraits.dart';

class HeroCharacter implements CombatDefinition {
  @override
  final String id;
  @override
  final String name;
  final String subtitle;
  final PersonalityClass characterClass;
  final CoreAttributes attributes;
  final AnatomicalLoadout loadout;
  final Vitals vitals;
  final String description;
  final List<String> availableSkills;

  /// Talent node ids this hero owns. Every hero starts with their tree's root
  /// (tier I) and nothing else.
  final Set<String> unlockedTalents;

  /// Full-length portrait asset, chosen at the start of a new game.
  final String portrait;

  HeroCharacter({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.characterClass,
    required this.attributes,
    required this.loadout,
    required this.vitals,
    required this.description,
    List<String>? availableSkills,
    Set<String>? unlockedTalents,
    String? portrait,
  })  : availableSkills = availableSkills ?? characterClass.availableSkills,
        unlockedTalents = unlockedTalents ?? _startingTalents(characterClass),
        portrait = portrait ?? HeroPortraits.defaultFor(characterClass.type);

  static Set<String> _startingTalents(PersonalityClass c) {
    final tree = TalentTree.forClass(c.type);
    return tree == null ? <String>{} : {tree.rootId};
  }

  TalentTree? get talentTree => TalentTree.forClass(characterClass.type);

  TalentEffect get talentEffect => talentTree?.effectOf(unlockedTalents) ?? TalentEffect.none;
}
