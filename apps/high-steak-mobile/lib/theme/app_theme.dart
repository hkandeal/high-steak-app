import 'package:flutter/material.dart';

import 'app_palette.dart';

abstract final class AppTheme {
  static const _displayFamily = 'Georgia';
  static const _bodyFamily = 'Roboto';

  static ThemeData build(AppThemeVariant variant) {
    final palette = AppPalette.forVariant(variant);
    final isDark = palette.brightness == Brightness.dark;

    final scheme = isDark
        ? ColorScheme.dark(
            primary: palette.ember,
            onPrimary: palette.cream,
            secondary: palette.gold,
            onSecondary: palette.charcoal,
            surface: palette.charcoalLight,
            onSurface: palette.cream,
            error: palette.ember,
            onError: palette.cream,
          )
        : ColorScheme.light(
            primary: palette.ember,
            onPrimary: Colors.white,
            secondary: palette.gold,
            onSecondary: palette.cream,
            surface: palette.charcoalLight,
            onSurface: palette.cream,
            error: palette.emberDark,
            onError: Colors.white,
          );

    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.charcoal,
      fontFamily: _bodyFamily,
      extensions: [palette],
    );

    final textTheme = base.textTheme.copyWith(
      headlineLarge: TextStyle(
        fontFamily: _displayFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: palette.gold,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontFamily: _displayFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: palette.cream,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: palette.cream,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: palette.cream,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: palette.cream,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: palette.creamMuted,
        height: 1.45,
      ),
      labelLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: palette.cream,
        titleTextStyle: TextStyle(
          fontFamily: _displayFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: palette.gold,
        ),
        iconTheme: IconThemeData(color: palette.gold),
      ),
      cardTheme: CardThemeData(
        color: palette.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputBg,
        labelStyle: TextStyle(color: palette.creamMuted),
        hintStyle: TextStyle(color: palette.creamMuted.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.cardBorderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.cardBorderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.ember),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.ember,
          foregroundColor: isDark ? palette.cream : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.gold,
          side: BorderSide(color: palette.cardBorderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.gold),
      ),
      dividerTheme: DividerThemeData(color: palette.cardBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.charcoalLight,
        contentTextStyle: TextStyle(color: palette.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.gold),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.charcoalLight.withValues(alpha: 0.95),
        indicatorColor: palette.accentSelectedBg,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? palette.gold
                : palette.creamMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.gold
                : palette.creamMuted,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.ember,
        foregroundColor: isDark ? palette.cream : Colors.white,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
