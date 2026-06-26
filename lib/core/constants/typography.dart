import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class VitruvianTypography {
  /// Scholarly serif title font (*IM Fell English*)
  static TextStyle serifTitle({
    double fontSize = 24,
    Color color = VitruvianColors.agedBone,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.imFellEnglish(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  /// Scholarly serif body text (*EB Garamond*)
  static TextStyle serifBody({
    double fontSize = 16,
    Color color = VitruvianColors.agedBone,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
  }) {
    return GoogleFonts.ebGaramond(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// Technical monospace numeric data (*Fira Code*)
  static TextStyle monospaceData({
    double fontSize = 14,
    Color color = VitruvianColors.agedBone,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.firaCode(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
