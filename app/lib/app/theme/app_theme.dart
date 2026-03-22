import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _bg = Color(0xFF06111C);
  static const _surface = Color(0xFF0D1B2A);
  static const _surfaceHigh = Color(0xFF13273D);
  static const _outline = Color(0xFF28415B);
  static const _primary = Color(0xFF5EEAD4);
  static const _secondary = Color(0xFF60A5FA);
  static const _danger = Color(0xFFF87171);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      error: _danger,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bg,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceHigh.withOpacity(0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: _outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
