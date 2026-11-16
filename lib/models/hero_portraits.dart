import 'character_class.dart';

/// Hero portraits the player picks from at the start, three looks per path.
/// Full-length figures cut out on a transparent background.
class HeroPortraits {
  static const _dir = 'assets/images/portraits';

  static const Map<PersonalityClassType, List<String>> byClass = {
    PersonalityClassType.warrior: [
      '$_dir/hero_warrior_1.png',
      '$_dir/hero_warrior_2.png',
      '$_dir/hero_warrior_3.png',
    ],
    PersonalityClassType.sorcerer: [
      '$_dir/hero_sorcerer_1.png',
      '$_dir/hero_sorcerer_2.png',
      '$_dir/hero_sorcerer_3.png',
    ],
    PersonalityClassType.assassin: [
      '$_dir/hero_assassin_1.png',
      '$_dir/hero_assassin_2.png',
      '$_dir/hero_assassin_3.png',
    ],
  };

  static List<String> of(PersonalityClassType type) => byClass[type]!;

  /// The look a hero has until the player chooses one.
  static String defaultFor(PersonalityClassType type) => byClass[type]!.first;
}
