import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      canvasColor: const Color(0xFF000000),
      cardColor: const Color(0xFF111111),
      primaryColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        shape: RoundedRectangleBorder(side: BorderSide.none),
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBarrierColor: Color(0x99000000),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF141313),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFFFFFFFF),
        barBackgroundColor: Color(0xFF000000),
        scaffoldBackgroundColor: Color(0xFF000000),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF000000),
        surface: Color(0xFF000000),
        onSurface: Color(0xFFE5E2E1),
        surfaceTint: Colors.transparent,
        surfaceContainerHighest: Color(0xFF141416),
        surfaceContainerHigh: Color(0xFF111111),
        surfaceContainer: Color(0xFF0D0D0E),
        surfaceContainerLow: Color(0xFF080809),
        surfaceContainerLowest: Color(0xFF000000),
        error: Color(0xFFDC2626),
        onError: Color(0xFFFFFFFF),
        outline: Color(0xFF27272A),
        outlineVariant: Color(0xFF3F3F46),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
          color: const Color(0xFFFFFFFF),
          height: 1.1,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: const Color(0xFFFFFFFF),
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: const Color(0xFFFFFFFF),
          height: 1.3,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFFFFFFF),
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFA1A1AA),
          height: 1.4,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: const Color(0xFF71717A),
          height: 1.3,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: const Color(0xFFFFFFFF),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111111),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF71717A),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3F3F46), width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF27272A),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
