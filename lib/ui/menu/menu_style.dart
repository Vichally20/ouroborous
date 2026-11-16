import 'package:flutter/material.dart';

import '../../models/character_class.dart';

/// Colours and per-path accents for the main menu and onboarding.
class ChronicleStyle {
  static const ink = Color(0xFF0A0810);
  static const bone = Color(0xFFEDE6DA);
  static const muted = Color(0xFFA89C8C);
  static const faint = Color(0xFF5E5666);
  static const gold = Color(0xFFD9B26F);
  static const crimson = Color(0xFFC0504A);

  static Color pathColor(PersonalityClassType t) => switch (t) {
        PersonalityClassType.warrior => const Color(0xFFD0573F),
        PersonalityClassType.assassin => const Color(0xFF3FA39A),
        PersonalityClassType.sorcerer => const Color(0xFF7B67D8),
      };

  static IconData pathIcon(PersonalityClassType t) => switch (t) {
        PersonalityClassType.warrior => Icons.shield_outlined,
        PersonalityClassType.assassin => Icons.visibility_off_outlined,
        PersonalityClassType.sorcerer => Icons.auto_fix_high,
      };

  static String pathName(PersonalityClassType t) => switch (t) {
        PersonalityClassType.warrior => 'Warrior',
        PersonalityClassType.assassin => 'Assassin',
        PersonalityClassType.sorcerer => 'Sorcerer',
      };

  static String pathTagline(PersonalityClassType t) => switch (t) {
        PersonalityClassType.warrior => 'Steel and stamina. Holds the front line and hits hardest.',
        PersonalityClassType.assassin => 'Quick and precise. Strikes first, from range or shadow.',
        PersonalityClassType.sorcerer => 'Fragile but brilliant. Bends hermetic fire to their will.',
      };
}
