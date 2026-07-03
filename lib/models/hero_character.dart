import 'character_class.dart';
import 'attributes.dart';
import 'loadout.dart';
import 'vitals.dart';
import 'combat_models.dart';

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
  }) : availableSkills = availableSkills ?? characterClass.availableSkills;
}
