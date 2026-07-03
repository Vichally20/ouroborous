enum PersonalityClassType { warrior, sorcerer, assassin }

class PersonalityClass {
  final PersonalityClassType type;
  final String title;
  final String clinicalRationale;
  final int baseStr;
  final int baseDex;
  final int baseInt;
  final int baseCon;
  final List<String> availableSkills;

  const PersonalityClass({
    required this.type,
    required this.title,
    required this.clinicalRationale,
    required this.baseStr,
    required this.baseDex,
    required this.baseInt,
    required this.baseCon,
    this.availableSkills = const ['blood_falchion_strike', 'hermetic_firebolt'],
  });

  static const PersonalityClass warrior = PersonalityClass(
    type: PersonalityClassType.warrior,
    title: 'Anatomical Warrior',
    clinicalRationale: 'Hypertrophic musculature and reinforced bone density.',
    baseStr: 16,
    baseDex: 10,
    baseInt: 8,
    baseCon: 14,
    availableSkills: ['blood_falchion_strike', 'heavy_slash'],
  );

  static const PersonalityClass sorcerer = PersonalityClass(
    type: PersonalityClassType.sorcerer,
    title: 'Hermetic Sorcerer',
    clinicalRationale: 'Elevated cerebral capacity coupled with fragile skeletal frame.',
    baseStr: 8,
    baseDex: 10,
    baseInt: 18,
    baseCon: 10,
    availableSkills: ['hermetic_firebolt', 'blood_hex'],
  );

  static const PersonalityClass assassin = PersonalityClass(
    type: PersonalityClassType.assassin,
    title: 'Clinical Assassin',
    clinicalRationale: 'Severed pain receptors and acute vascular precision.',
    baseStr: 10,
    baseDex: 18,
    baseInt: 12,
    baseCon: 10,
    availableSkills: ['shadow_swipe', 'blood_falchion_strike'],
  );
}
