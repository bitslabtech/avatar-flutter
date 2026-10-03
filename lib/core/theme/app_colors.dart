// Avatar brand color constants
// Unified design tokens inspired by Avatar_project (Avatar Crimson & Charcoal Slate)
import 'package:flutter/material.dart';

class AppColors {
  // Private constructor
  AppColors._();

  // -------------------------------------------------------------
  // Signature Avatar SKW Brand Colors
  // -------------------------------------------------------------
  static const Color primary = Color(0xFFE52528); // Avatar Crimson
  static const Color primaryAccent = Color(0xFFE52528);

  // Surface & Background Colors
  static const Color surfaceDark = Color(0xFF212529); // Charcoal Slate
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceSubtle = Color(0xFFF7F8FA); // Soft Gray Surface
  static const Color backgroundLight = Color(0xFFFFFFFF); // Pure White Background

  // Dark Theme Backgrounds & Surfaces
  static const Color darkBackground = Color(0xFF14171A);
  static const Color darkSurface = Color(0xFF1E2226);
  static const Color darkCard = Color(0xFF1E2226);
  static const Color cardDark = Color(0xFF1E2226);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color backgroundBlack = Color(0xFF000000);

  // Typography & Text Colors
  static const Color textPrimary = Color(0xFF1C1E21); // Charcoal Black
  static const Color textMuted = Color(0xFF767E86); // Slate Gray
  static const Color textLight = Color(0xFFFFFFFF); // Pure White text
  static const Color textSecondary = Color(0xFF767E86);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  static const Color textDarkPrimary = Color(0xFF1C1E21);
  static const Color textDarkSecondary = Color(0xFF767E86);

  // Dealer Tier Gold Accents
  static const Color dealerGold = Color(0xFFC89B3C); // Dealer Gold
  static const Color dealerGoldSurface = Color(0xFFFFF8EC); // Golden Glow Surface

  // Border & Divider Colors
  static const Color borderLight = Color(0xFFE2E4E8);
  static const Color borderDark = Color(0xFF2E343A);
  static const Color borderGray = Color(0xFF2E343A);
  static const Color dividerGray = Color(0xFFE2E4E8);

  // Status & Utility Accents
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color accentWarm = Color(0xFFFF6B6B);

  // Shadows
  static const Color shadowDark = Color(0x33000000);
  static const Color shadowLight = Color(0x0A000000);

  // -------------------------------------------------------------
  // Backward-Compatibility Aliases
  // (Ensures all existing screens adapt seamlessly to the new Crimson theme)
  // -------------------------------------------------------------
  static const Color primaryBlue = primary;
  static const Color primaryElectric = primaryAccent;
  static const Color primaryRed = primary;
  static const Color primaryBlueDark = primary;
  static const Color primaryBlueGlow = Color(0x33E52528);

  /// Returns the signature brand color
  static Color primaryBlueFor(bool isDark) => primary;
}

