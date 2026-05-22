/// Avatar brand color constants
/// Defines the color palette for the premium dark theme
import 'package:flutter/material.dart';

class AppColors {
  // Primary brand color - Avatar red
  static const Color primaryRed = Color(0xFFE63946);

  // Primary blue — light mode (rich, vivid: #395bc1ff)
  static const Color primaryBlue = Color(0xFF1349EC);

  // Primary blue — dark mode (white-blue: #B3D9FF)
  // Almost white with a blue tint — maximum readability, zero eye strain on dark backgrounds.
  static const Color primaryBlueDark = Color(0xFFB3D9FF);

  /// Returns the correct primary blue depending on brightness.
  /// Usage: AppColors.primaryBlueFor(isDark)
  static Color primaryBlueFor(bool isDark) =>
      isDark ? primaryBlueDark : primaryBlue;

  // Background colors
  static const Color backgroundLight = Color(0xFFF6F6F8); // From HTML design
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF2A2A2A);
  
  // Text colors - Soft whites and grays
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);
  
  // Accent colors
  static const Color accentWarm = Color(0xFFFF6B6B);
  static const Color successGreen = Color(0xFF51CF66);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color warningOrange = Color(0xFFFFA726);
  
  // Border and divider colors
  static const Color borderGray = Color(0xFF404040);
  static const Color dividerGray = Color(0xFF333333);
  
  // Shadow colors for depth
  static const Color shadowDark = Color(0x40000000);
  
  // Private constructor to prevent instantiation
  AppColors._();
}


