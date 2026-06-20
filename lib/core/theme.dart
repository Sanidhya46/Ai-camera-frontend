/// Centralized theme configuration for the SmartShutter app.
/// Supports both Dark and Light themes with reactive switching.
/// Dark theme: glassmorphic obsidian/indigo aesthetic.
/// Light theme: clean white/lavender design.
/// All visual design consistency is maintained through this single theme file.

import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand colors (shared across both themes) ───
  static const Color brand = Color(0xFF6D5EFC);   // Wireframe brand
  static const Color brand2 = Color(0xFFD85FE5);  // Wireframe brand-2
  static const Color ok = Color(0xFF0F9D58);      // Wireframe ok
  static const Color warn = Color(0xFFD97706);    // Wireframe warn
  static const Color danger = Color(0xFFC62828);  // Wireframe danger

  // ═══════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════
  static const Color darkBgStart = Color(0xFF090D1A);
  static const Color darkBgEnd = Color(0xFF1E1B4B);
  static const Color darkInk = Color(0xFFF3F4F6);
  static const Color darkMuted = Color(0xFF94A3B8);
  static const Color darkLine = Color(0xFF334155);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);

  // ═══════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════
  static const Color lightBgStart = Color(0xFFF7F8FC);
  static const Color lightBgEnd = Color(0xFFEEF2FF);
  static const Color lightInk = Color(0xFF1F2937);
  static const Color lightMuted = Color(0xFF6B7280);
  static const Color lightLine = Color(0xFFDBE1EA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // ─── Dynamic color accessors ───
  static Color ink(bool isDark) => isDark ? darkInk : lightInk;
  static Color muted(bool isDark) => isDark ? darkMuted : lightMuted;
  static Color line(bool isDark) => isDark ? darkLine : lightLine;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;

  // ─── Background gradient ───
  static BoxDecoration gradientBg(bool isDark) {
    return isDark
        ? const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF070A13),
                Color(0xFF0F172A),
                Color(0xFF1E1B4B),
              ],
            ),
          )
        : const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF7F8FC),
                Color(0xFFEEF2FF),
              ],
            ),
          );
  }

  // ─── Glassmorphic card decoration ───
  static BoxDecoration glassmorphicDecoration(bool isDark) {
    return isDark
        ? BoxDecoration(
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
          )
        : BoxDecoration(
            color: Colors.white,
            border: Border.all(color: lightLine, width: 1),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          );
  }

  static BoxDecoration glassmorphicCustom({
    required double radius,
    Color? borderColor,
    required bool isDark,
  }) {
    return isDark
        ? BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.45),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: brand.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          )
        : BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: borderColor ?? lightLine.withOpacity(0.6),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          );
  }

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brand, brand2],
  );

  // ─── Brand gradient decoration for buttons ───
  static BoxDecoration get brandGradientDecoration {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [brand, Color(0xFFD85FE5)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: brand.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: brand,
      colorScheme: const ColorScheme.dark(
        primary: brand,
        secondary: brand2,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: const Color(0xFF070A13),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: darkInk, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Outfit'),
        titleLarge: TextStyle(color: darkInk, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Outfit'),
        bodyLarge: TextStyle(color: darkInk, fontSize: 16, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: darkInk, fontSize: 14, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: darkMuted, fontSize: 13, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkInk,
          side: const BorderSide(color: darkLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkLine.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkLine.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: darkMuted, fontFamily: 'Inter'),
        hintStyle: TextStyle(color: darkMuted.withOpacity(0.6), fontFamily: 'Inter'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      primaryColor: brand,
      colorScheme: const ColorScheme.light(
        primary: brand,
        secondary: brand2,
        surface: lightSurface,
      ),
      scaffoldBackgroundColor: lightBgStart,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: lightInk, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Outfit'),
        titleLarge: TextStyle(color: lightInk, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Outfit'),
        bodyLarge: TextStyle(color: lightInk, fontSize: 16, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: lightInk, fontSize: 14, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: lightMuted, fontSize: 13, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightInk,
          side: const BorderSide(color: lightLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: lightMuted, fontFamily: 'Inter'),
        hintStyle: TextStyle(color: lightMuted.withOpacity(0.6), fontFamily: 'Inter'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

}
