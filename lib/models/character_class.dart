enum PersonalityClassType { warrior, sorcerer, assassin }

class PersonalityClass {
  final PersonalityClassType type;
  final String title;
  final String clinicalRationale;
  final int baseStr;
  final int baseDex;
  final int baseInt;
  final int baseCon;

  const PersonalityClass({
    required this.type,
    required this.title,
    required this.clinicalRationale,
    required this.baseStr,
    required this.baseDex,
    required this.baseInt,
    required this.baseCon,
  });

  static const PersonalityClass warrior = PersonalityClass(
    type: PersonalityClassType.warrior,
    title: 'Anatomical Warrior',
    clinicalRationale: 'Hypertrophic musculature and reinforced bone density.',
    baseStr: 16,
    baseDex: 10,
    baseInt: 8,
    baseCon: 14,
  );

  static const PersonalityClass sorcerer = PersonalityClass(
    type: PersonalityClassType.sorcerer,
    title: 'Hermetic Sorcerer',
    clinicalRationale: 'Elevated cerebral capacity coupled with fragile skeletal frame.',
    baseStr: 8,
    baseDex: 10,
    baseInt: 18,
    baseCon: 10,
  );

  static const PersonalityClass assassin = PersonalityClass(
    type: PersonalityClassType.assassin,
    title: 'Clinical Assassin',
    clinicalRationale: 'Severed pain receptors and acute vascular precision.',
    baseStr: 10,
    baseDex: 18,
    baseInt: 12,
    baseCon: 10,
  );
}
