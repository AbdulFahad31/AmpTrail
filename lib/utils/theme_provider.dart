import 'package:flutter/material.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart'; // Added import for GoogleFonts

class ThemeProvider extends ChangeNotifier {
  final ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark; // Corrected isDarkMode getter

  ThemeProvider();

  void toggleTheme(bool isDark) {
    // Theme is locked to Dark mode
  }

  // Define Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: Colors.white,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: Color(0xFF0F172A),
    ),
    useMaterial3: true,
    fontFamily: 'Outfit', // Assuming global font
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1E293B), // Dark background even in light mode for contrast
      contentTextStyle: GoogleFonts.outfit(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Define Dark Theme (Matching current AppColors)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    dividerColor: AppColors.surfaceLight,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.background,
      onSurface: AppColors.textPrimary,
    ),
    useMaterial3: true,
    fontFamily: 'Outfit',
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: GoogleFonts.outfit(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
