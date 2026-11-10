import 'package:flutter/material.dart';

abstract final class EduNoteColors {
  static const navy = Color(0xFF12304A);
  static const blue = Color(0xFF2878B8);
  static const paleBlue = Color(0xFFEAF4FB);
  static const ink = Color(0xFF182735);
  static const muted = Color(0xFF657786);
  static const canvas = Color(0xFFF6F8FA);
  static const green = Color(0xFF23835B);
  static const red = Color(0xFFB93838);
}

abstract final class EduNoteTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: EduNoteColors.blue,
      primary: EduNoteColors.navy,
      surface: Colors.white,
      error: EduNoteColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: EduNoteColors.canvas,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: EduNoteColors.canvas,
        foregroundColor: EduNoteColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE7EDF1)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2E9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2E9)),
        ),
      ),
    );
  }
}
