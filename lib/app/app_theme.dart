import 'package:flutter/material.dart';

/// Brand seed color (refined teal/green).
const _seed = Color(0xFF14B8A6);

class AppTheme {
  static const _radiusCard = 16.0;
  static const _radiusField = 12.0;

  static const _fieldPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  static const _tilePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 2);
  static const _cardMargin =
      EdgeInsets.zero; // IMPORTANT: keep same in both themes

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardColor,
    required Color inputFill,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,

      // Keep AppBar behavior identical -> no "jump"
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor:
            colorScheme.surface, // keep solid in both to avoid visual shift
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        margin: _cardMargin, // IMPORTANT: same margin in both
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: _tilePadding, // IMPORTANT: same in both
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: _fieldPadding, // IMPORTANT: same in both
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2B3440) : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2B3440) : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
      ),

      iconTheme: IconThemeData(color: colorScheme.onSurface.withOpacity(0.85)),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF1E242B) : const Color(0xFF111827),
        contentTextStyle:
            TextStyle(color: isDark ? Colors.white : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(elevation: 2),
    );
  }

  // LIGHT (aligned)
  static final ThemeData light = _base(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00796B),
      onPrimary: Colors.white,
      secondary: Color(0xFFFFC107),
      onSecondary: Colors.black,
      surface: Color(0xFFFFFFFF), // make AppBar/Card consistent surface base
      onSurface: Color(0xFF1F2937),
      error: Color(0xFFD32F2F),
      onError: Colors.white,
    ),
    scaffoldBg: const Color(0xFFF9FAFB),
    cardColor: const Color(0xFFFFFFFF),
    inputFill: const Color(0xFFFFFFFF),
  );

  // DARK (aligned)
  static final ThemeData dark = _base(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF161A1F),
    ),
    scaffoldBg: const Color(0xFF0F1114),
    cardColor: const Color(0xFF161A1F),
    inputFill: const Color(0xFF151A1E),
  );
}
