import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

class ManuscriptTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: VitruvianColors.voidBlack,
      primaryColor: VitruvianColors.sepiaUmber,
      colorScheme: const ColorScheme.dark(
        primary: VitruvianColors.sepiaUmber,
        secondary: VitruvianColors.agedBone,
        error: VitruvianColors.rustBlood,
        surface: VitruvianColors.voidBlack,
      ),
      dividerTheme: const DividerThemeData(
        color: VitruvianColors.etchedHairline,
        thickness: 1.0,
        space: 1.0,
      ),
      cardTheme: const CardThemeData(
        color: VitruvianColors.voidBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Razor-sharp 0px corner radiuses
          side: BorderSide(color: VitruvianColors.sepiaUmber, width: 1.0), // 1px etched hairlines
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VitruvianColors.voidBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: VitruvianTypography.serifTitle(fontSize: 22),
      ),
    );
  }
}
