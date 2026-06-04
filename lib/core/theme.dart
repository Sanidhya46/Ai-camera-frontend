import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF090D1A);
  static const Color backgroundEnd = Color(0xFF1E1B4B);
  
  static const Color ink = Color(0xFFF3F4F6); // White/slate-100
  static const Color muted = Color(0xFF94A3B8); // Slate-400
  static const Color line = Color(0xff334155); // Slate-700
  
  static const Color brand = Color(0xFF8B5CF6); // Neon Violet
  static const Color brand2 = Color(0xFF06B6D4); // Glowing Cyan
  
  static const Color ok = Color(0xFF10B981); // Neon Green
  static const Color warn = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Neon Rose

  static BoxDecoration get gradientBg {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF070A13), // Ultra dark obsidian
          Color(0xFF0F172A), // Dark slate
          Color(0xFF1E1B4B), // Midnight indigo
        ],
      ),
    );
  }

  static BoxDecoration get glassmorphicDecoration {
    return BoxDecoration(
      color: const Color(0xFF1E293B).withOpacity(0.45),
      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: brand.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glassmorphicCustom({required double radius, Color? borderColor}) {
    return BoxDecoration(
      color: const Color(0xFF1E293B).withOpacity(0.45),
      border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.08), width: 1.5),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: brand.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static ThemeData get theme {
    return ThemeData.dark().copyWith(
      primaryColor: brand,
      colorScheme: const ColorScheme.dark(
        primary: brand,
        secondary: brand2,
        surface: Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: const Color(0xFF070A13),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Outfit'),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Outfit'),
        bodyLarge: TextStyle(color: ink, fontSize: 16, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: ink, fontSize: 14, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: muted, fontSize: 13, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
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
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter'),
        ),
      ),
    );
  }
}
