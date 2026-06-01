import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFFF7F8FC);
  static const Color backgroundEnd = Color(0xFFEEF2FF);
  static const Color ink = Color(0xFF1F2937);
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFDBE1EA);
  static const Color brand = Color(0xFF6D5EFC);
  static const Color brand2 = Color(0xFFD85FE5);
  static const Color ok = Color(0xFF0F9D58);
  static const Color warn = Color(0xFFD97706);
  static const Color danger = Color(0xFFC62828);
  
  static ThemeData get theme {
    return ThemeData(
      primaryColor: brand,
      scaffoldBackgroundColor: Colors.transparent, // Handled by gradient container in scaffold
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.bold, fontSize: 22),
        bodyLarge: TextStyle(color: ink, fontSize: 16),
        bodyMedium: TextStyle(color: ink, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}
