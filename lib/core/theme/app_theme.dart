/// Avatar app theme configuration
/// Material 3 dark theme with premium, minimal, Apple-like styling
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// Main dark theme for the app
  /// Uses Material 3 with custom Avatar branding
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme - dark theme with sky-blue primary (soft on dark surfaces)
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryBlueDark,  // #90CAF9 very light pastel blue
        secondary: AppColors.accentWarm,
        surface: AppColors.surfaceDark,
        background: AppColors.backgroundBlack,
        error: AppColors.errorRed,
        onPrimary: AppColors.backgroundBlack,  // Dark text on light blue button
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.backgroundBlack,
      
      // AppBar theme - minimal, premium
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      
      // Card theme - rounded with subtle shadow
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 4,
        shadowColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Input decoration theme - rounded, minimal
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlueDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),
      
      // Button themes - rounded, premium
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlueDark,
          foregroundColor: AppColors.backgroundBlack, // Dark text on sky-blue
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Text theme - clean, minimal typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.4,
        ),
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerGray,
        thickness: 1,
        space: 1,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }
  
  /// Light theme for the app (Matches HTML design)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme - light theme
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryRed,
        surface: Colors.white,
        background: AppColors.backgroundLight,
        error: AppColors.errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.backgroundBlack,
        onBackground: AppColors.backgroundBlack,
        onError: Colors.white,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.backgroundBlack),
        titleTextStyle: TextStyle(
          color: AppColors.backgroundBlack,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.backgroundBlack, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.backgroundBlack, fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.backgroundBlack, fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF64748B), fontSize: 14), // Slate-500
      ),
      
      iconTheme: const IconThemeData(
        color: Color(0xFF64748B), // Slate-500
        size: 24,
      ),
    );
  }

  // Private constructor to prevent instantiation
  AppTheme._();
}

