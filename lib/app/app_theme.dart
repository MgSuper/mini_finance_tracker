import 'package:flutter/material.dart';

/// Luxury dark + gold accent theme (inspired by the screenshot)
class AppTheme {
  static const _radiusCard = 18.0;
  static const _radiusField = 14.0;
  static const _radiusButton = 14.0;

  static const _fieldPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 14);
  static const _tilePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 2);

  // IMPORTANT: keep same in both themes (prevents layout "jump")
  static const _cardMargin = EdgeInsets.zero;

  // Brand accents (gold)
  static const _gold = Color(0xFFD6B25E); // warm gold
  static const _goldSoft = Color(0xFFBFA45A);

  // Dark surfaces (matte)
  static const _darkBg = Color(0xFF0B0D10);
  static const _darkSurface = Color(0xFF12151A);
  static const _darkSurface2 = Color(0xFF151A20);
  static const _darkOutline = Color(0xFF232A34);

  // Light surfaces (still slightly warm, not pure white)
  static const _lightBg = Color(0xFFF6F6F3);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurface2 = Color(0xFFF9FAFB);
  static const _lightOutline = Color(0xFFE7E7E2);

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color surface,
    required Color surface2,
    required Color outline,
  }) {
    final isDark = brightness == Brightness.dark;

    // Small helpers
    final onSurfaceMuted = scheme.onSurface.withAlpha(isDark ? 179 : 195);
    final onSurfaceFaint = scheme.onSurface.withAlpha(isDark ? 115 : 135);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,

      // Keep AppBar behavior identical -> no "jump"
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface.withAlpha(225)),
      ),

      dividerTheme: DividerThemeData(
        color: outline.withAlpha(isDark ? 230 : 255),
        thickness: 1,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 1,
        margin: _cardMargin,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
          side: BorderSide(
            color: outline.withAlpha(isDark ? 230 : 255),
            width: 1,
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(contentPadding: _tilePadding),

      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: onSurfaceMuted),
        bodySmall: TextStyle(color: onSurfaceFaint),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: _fieldPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: BorderSide(color: outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: BorderSide(color: outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: onSurfaceFaint),
        hintStyle: TextStyle(color: onSurfaceFaint),
        prefixIconColor: onSurfaceFaint,
        suffixIconColor: onSurfaceFaint,
      ),

      iconTheme: IconThemeData(color: scheme.onSurface.withAlpha(209)),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusButton),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusButton),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF151A20) : const Color(0xFF111827),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // LIGHT: warm, clean, gold accent
  static final ThemeData light = _base(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: _goldSoft,
      onPrimary: Colors.black,
      secondary: _gold,
      onSecondary: Colors.black,
      surface: _lightSurface,
      onSurface: Color(0xFF151515),
      error: Color(0xFFD32F2F),
      onError: Colors.white,
    ),
    scaffoldBg: _lightBg,
    surface: _lightSurface,
    surface2: _lightSurface2,
    outline: _lightOutline,
  );

  // DARK: matte black, gold highlight
  static final ThemeData dark = _base(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: _gold,
      onPrimary: Color(0xFF0B0D10),
      secondary: _goldSoft,
      onSecondary: Color(0xFF0B0D10),
      surface: _darkSurface,
      onSurface: Color(0xFFEDEDED),
      error: Color(0xFFEF4444),
      onError: Colors.black,
    ),
    scaffoldBg: _darkBg,
    surface: _darkSurface,
    surface2: _darkSurface2,
    outline: _darkOutline,
  );
}
