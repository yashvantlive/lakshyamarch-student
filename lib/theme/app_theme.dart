import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static bool isDarkMode = false;

  // Premium Maroon Palette (Official Brand Colors)
  static const Color _primaryConst = Color(0xFF650D0B); // Maroon
  static const Color _primaryLightConst = Color(0xFFEF5350); // Lighter Maroon for Dark Mode

  static Color get primary => isDarkMode ? _primaryLightConst : _primaryConst;
  static Color get primaryLight => isDarkMode ? const Color(0xFFEF9A9A) : const Color(0xFF8B1815);
  static const Color primaryDark = Color(0xFF430504);
  
  static Color get accent => isDarkMode ? _primaryLightConst : const Color(0xFF8B1815);
  
  static const Color _lightBackground = Color(0xFFF8FAFC); // slate-50
  static const Color _lightSurface = Colors.white;
  static const Color _lightBorder = Color(0xFFE2E8F0); // slate-200
  
  static const Color _lightTextBase = Color(0xFF0F172A); // slate-900
  static const Color _lightTextMuted = Color(0xFF64748B); // slate-500
  
  static const Color darkBackground = Color(0xFF0B0F19); // slate-955
  static const Color darkSurface = Color(0xFF1E293B); // slate-800
  static const Color darkBorder = Color(0xFF334155); // slate-700
  static const Color darkTextBase = Color(0xFFF8FAFC); // slate-50
  static const Color darkTextMuted = Color(0xFF94A3B8); // slate-400

  static Color get background => isDarkMode ? darkBackground : _lightBackground;
  static Color get surface => isDarkMode ? darkSurface : _lightSurface;
  static Color get border => isDarkMode ? darkBorder : _lightBorder;
  static Color get textBase => isDarkMode ? darkTextBase : _lightTextBase;
  static Color get textMuted => isDarkMode ? darkTextMuted : _lightTextMuted;

  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color danger = Color(0xFFEF4444); // red-500

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Coaching Palette (Emerald/Teal)
  static const Color coachingPrimary = Color(0xFF059669); // emerald-600
  static const Color coachingAccent = Color(0xFF0D9488); // teal-600
  
  static const LinearGradient coachingGradient = LinearGradient(
    colors: [coachingPrimary, coachingAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // School Wing = Indigo/Primary, Coaching Wing = Emerald/Green
  static Color getWingColor(String? wing) {
    return wing == 'coaching' ? coachingPrimary : primary;
  }

  static LinearGradient getWingGradient(String? wing) {
    return wing == 'coaching' ? coachingGradient : primaryGradient;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: _lightSurface,
        background: _lightBackground,
      ),
      scaffoldBackgroundColor: _lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: _lightTextBase),
        titleTextStyle: TextStyle(color: _lightTextBase, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: _lightTextBase),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: _lightTextBase),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: _lightTextBase),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, color: _lightTextBase),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: _lightTextBase, height: 1.5),
        labelMedium: GoogleFonts.outfit(fontSize: 12, color: _lightTextMuted, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }


  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: accent,
        surface: darkSurface,
        background: darkBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkTextBase),
        titleTextStyle: TextStyle(color: darkTextBase, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: darkTextBase),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: darkTextBase),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextBase),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, color: darkTextBase),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: darkTextBase, height: 1.5),
        labelMedium: GoogleFonts.outfit(fontSize: 12, color: darkTextMuted, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: darkTextMuted),
        hintStyle: const TextStyle(color: darkTextMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
