import 'character_class.dart';
import 'attributes.dart';
import 'loadout.dart';
import 'vitals.dart';

class HeroCharacter {
  final String id;
  final String name;
  final String subtitle;
  final PersonalityClass characterClass;
  final CoreAttributes attributes;
  final AnatomicalLoadout loadout;
  final Vitals vitals;
  final String description;

  HeroCharacter({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.characterClass,
    required this.attributes,
    required this.loadout,
    required this.vitals,
    required this.description,
  });
}
