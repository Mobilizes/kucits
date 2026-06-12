import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ITS Branding Colors
  static const Color itsBlue = Color(0xFF004B93);
  static const Color itsLightBlue = Color(0xFF4FA1D8);
  static const Color itsDarkBlue = Color(0xFF0A1D37);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF4F7FC);
  static const Color lightSurface = Colors.white;
  static const Color lightTextMain = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightActiveContainer = Color(0xFFE6F0FA);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextMain = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkActiveContainer = Color(0xFF2C2C2C);

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: itsBlue,
        onPrimary: Colors.white,
        primaryContainer: lightActiveContainer,
        onPrimaryContainer: itsBlue,
        secondary: itsLightBlue,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFEBF5FF),
        onSecondaryContainer: itsBlue,
        surface: lightSurface,
        onSurface: lightTextMain,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: Color(0xFFCBD5E1),
        outlineVariant: Color(0xFFE2E8F0),
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextMain,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightTextMain),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.montserratTextTheme(baseTheme.textTheme).copyWith(
        titleLarge: GoogleFonts.montserrat(
          textStyle: baseTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: lightTextMain,
          ),
        ),
        headlineMedium: GoogleFonts.montserrat(
          textStyle: baseTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: lightTextMain,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: itsLightBlue,
        onPrimary: darkBackground,
        primaryContainer: darkActiveContainer,
        onPrimaryContainer: Colors.white,
        secondary: itsBlue,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF2C2C2C),
        onSecondaryContainer: Colors.white,
        surface: darkSurface,
        onSurface: darkTextMain,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: Color(0xFF4B5563),
        outlineVariant: Color(0xFF374151),
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextMain,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextMain),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF374151)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF374151),
        thickness: 1,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.montserratTextTheme(baseTheme.textTheme).copyWith(
        titleLarge: GoogleFonts.montserrat(
          textStyle: baseTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: darkTextMain,
          ),
        ),
        headlineMedium: GoogleFonts.montserrat(
          textStyle: baseTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: darkTextMain,
          ),
        ),
      ),
    );
  }
}
