import 'package:flutter/material.dart';

abstract final class EduNoteColors {
  // Brand palette - Academic Modern Warm
  static const primary = Color(0xFF1E293B); // Deep slate navy
  static const primaryDark = Color(0xFF0F172A);
  static const primaryLight = Color(0xFF334155);

  static const accent = Color(0xFF4F46E5); // Rich indigo
  static const accentLight = Color(0xFFEEF2FF);
  static const accentGradientStart = Color(0xFF4338CA);
  static const accentGradientEnd = Color(0xFF6366F1);

  // Warm gold / amber highlights
  static const amber = Color(0xFFD97706);
  static const amberLight = Color(0xFFFEF3C7);
  static const amberGlow = Color(0xFFF59E0B);

  // Success / Emerald validation
  static const emerald = Color(0xFF059669);
  static const emeraldLight = Color(0xFFD1FAE5);
  static const emeraldGlow = Color(0xFF10B981);

  // Error / Crimson
  static const crimson = Color(0xFFDC2626);
  static const crimsonLight = Color(0xFFFEE2E2);

  // Neutrals & Surfaces
  static const background = Color(0xFFF8FAFC); // Soft cool white
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const cardBorder = Color(0xFFE2E8F0);
  static const divider = Color(0xFFE2E8F0);

  // Typography colors
  static const ink = Color(0xFF0F172A); // High-emphasis
  static const textSecondary = Color(0xFF475569); // Medium-emphasis
  static const muted = Color(0xFF64748B); // Low-emphasis
  static const subtle = Color(0xFF94A3B8);

  // Legacy mappings for backward compatibility
  static const navy = primary;
  static const blue = accent;
  static const paleBlue = accentLight;
  static const canvas = background;
  static const green = emerald;
  static const red = crimson;
}

abstract final class EduNoteShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const floating = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const primaryGlow = [
    BoxShadow(
      color: Color(0x334F46E5),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const amberGlow = [
    BoxShadow(
      color: Color(0x33F59E0B),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

abstract final class EduNoteTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: EduNoteColors.accent,
      primary: EduNoteColors.accent,
      secondary: EduNoteColors.amber,
      surface: EduNoteColors.surface,
      error: EduNoteColors.crimson,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: EduNoteColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: EduNoteColors.background,
        foregroundColor: EduNoteColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: EduNoteColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: EduNoteColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: EduNoteColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EduNoteColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: EduNoteColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: EduNoteColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: EduNoteColors.accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: EduNoteColors.crimson),
        ),
        labelStyle: const TextStyle(color: EduNoteColors.muted, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: EduNoteColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EduNoteColors.primary,
          side: const BorderSide(color: EduNoteColors.cardBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: EduNoteColors.accentLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: EduNoteColors.accent, size: 24);
          }
          return const IconThemeData(color: EduNoteColors.muted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: EduNoteColors.accent,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: EduNoteColors.muted,
          );
        }),
      ),
    );
  }
}
