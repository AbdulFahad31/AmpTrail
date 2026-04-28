
import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0F172A); // Dark Slate
  static const Color surface = Color(0xFF1E293B); // Lighter Slate
  static const Color surfaceLight = Color(0xFF334155);

  // Primaries
  static const Color primary = Color(0xFF00E676); // Electric Green
  static const Color secondary = Color(0xFF2979FF); // Electric Blue
  static const Color accent = Color(0xFFFFC400); // Amber

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFF64748B);

  // Functional
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFFC400); // Amber for pending status
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
