import 'package:flutter/material.dart';
import '../utils/google_fonts.dart';

class AppTheme {
  // ─── Color Palette (SIMRS Vue Premium Light Theme) ───
  static const Color primary = Color(0xFF059669);      // Emerald 600
  static const Color primaryDark = Color(0xFF047857);  // Emerald 700
  static const Color primaryLight = Color(0xFF10B981); // Emerald 500
  static const Color accent = Color(0xFF10B981);       // Emerald 500
  static const Color accentAlt = Color(0xFF0EA5E9);    // Sky 500

  // Surface Colors (Slate Light Mode)
  static const Color bgDark = Color(0xFFF8FAFC);       // Slate 50 (Scaffold Background)
  static const Color bgCard = Color(0xFFFFFFFF);       // Card Background
  static const Color bgSurface = Color(0xFFF1F5F9);    // Slate 100 (Inputs/Containers)
  static const Color bgCardLight = Color(0xFFF1F5F9);  // Slate 100

  // Text Colors (Dark Slate)
  static const Color textPrimary = Color(0xFF0F172A);  // Slate 900
  static const Color textSecondary = Color(0xFF475569);// Slate 600
  static const Color textMuted = Color(0xFF94A3B8);    // Slate 400

  // Status Colors
  static const Color success = Color(0xFF10B981);      // Emerald 500
  static const Color warning = Color(0xFFF59E0B);      // Amber 500
  static const Color danger = Color(0xFFEF4444);       // Red 500
  static const Color info = Color(0xFF3B82F6);         // Blue 500

  static const Color divider = Color(0xFFE2E8F0);      // Slate 200 (Card Borders)

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgDark, Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Theme Data ───────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        error: danger,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: const CardTheme(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: divider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
    );
  }
}
