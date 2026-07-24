import 'package:flutter/material.dart';

class AdminTheme {
  static const Color darkBg = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color sidebarBg = Color(0xFF1E293B);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRose = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData get themeData {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBg,
      cardColor: cardBg,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentEmerald,
        surface: cardBg,
        error: errorRose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: sidebarBg,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
