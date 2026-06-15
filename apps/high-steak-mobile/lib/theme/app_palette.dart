import 'package:flutter/material.dart';

enum AppThemeVariant { ember, steam }

/// Color tokens aligned with apps/high-steak-web/src/index.css
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.charcoal,
    required this.charcoalLight,
    required this.charcoalDeep,
    required this.ember,
    required this.emberDark,
    required this.gold,
    required this.cream,
    required this.creamMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.cardBorderStrong,
    required this.inputBg,
    required this.errorText,
    required this.flameGlow,
    required this.accentSelectedBg,
    required this.brightness,
  });

  final Color charcoal;
  final Color charcoalLight;
  final Color charcoalDeep;
  final Color ember;
  final Color emberDark;
  final Color gold;
  final Color cream;
  final Color creamMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color cardBorderStrong;
  final Color inputBg;
  final Color errorText;
  final Color flameGlow;
  final Color accentSelectedBg;
  final Brightness brightness;

  static const emberTheme = AppPalette(
    charcoal: Color(0xFF120806),
    charcoalLight: Color(0xFF1F0F0C),
    charcoalDeep: Color(0xFF0A0403),
    ember: Color(0xFFC43A2A),
    emberDark: Color(0xFF8F2418),
    gold: Color(0xFFD4A054),
    cream: Color(0xFFF5EBE0),
    creamMuted: Color(0xFFB8A89A),
    cardBg: Color(0x0AFFFFFF),
    cardBorder: Color(0x26D4A054),
    cardBorderStrong: Color(0x40D4A054),
    inputBg: Color(0x59000000),
    errorText: Color(0xFFFFB4A8),
    flameGlow: Color(0x2EC43A2A),
    accentSelectedBg: Color(0x26D4A054),
    brightness: Brightness.dark,
  );

  static const steamTheme = AppPalette(
    charcoal: Color(0xFFFAF6F1),
    charcoalLight: Color(0xFFFFF9F4),
    charcoalDeep: Color(0xFFF3EBE3),
    ember: Color(0xFFD4462A),
    emberDark: Color(0xFFA8321F),
    gold: Color(0xFFE8953A),
    cream: Color(0xFF3D2817),
    creamMuted: Color(0xFF7A6554),
    cardBg: Color(0xC7FFFFFF),
    cardBorder: Color(0x38E8953A),
    cardBorderStrong: Color(0x61E8953A),
    inputBg: Color(0xF5FFFCF8),
    errorText: Color(0xFFA8321F),
    flameGlow: Color(0x61FFAA50),
    accentSelectedBg: Color(0x33E8953A),
    brightness: Brightness.light,
  );

  static AppPalette forVariant(AppThemeVariant variant) {
    return variant == AppThemeVariant.steam ? steamTheme : emberTheme;
  }

  @override
  AppPalette copyWith({
    Color? charcoal,
    Color? charcoalLight,
    Color? charcoalDeep,
    Color? ember,
    Color? emberDark,
    Color? gold,
    Color? cream,
    Color? creamMuted,
    Color? cardBg,
    Color? cardBorder,
    Color? cardBorderStrong,
    Color? inputBg,
    Color? errorText,
    Color? flameGlow,
    Color? accentSelectedBg,
    Brightness? brightness,
  }) {
    return AppPalette(
      charcoal: charcoal ?? this.charcoal,
      charcoalLight: charcoalLight ?? this.charcoalLight,
      charcoalDeep: charcoalDeep ?? this.charcoalDeep,
      ember: ember ?? this.ember,
      emberDark: emberDark ?? this.emberDark,
      gold: gold ?? this.gold,
      cream: cream ?? this.cream,
      creamMuted: creamMuted ?? this.creamMuted,
      cardBg: cardBg ?? this.cardBg,
      cardBorder: cardBorder ?? this.cardBorder,
      cardBorderStrong: cardBorderStrong ?? this.cardBorderStrong,
      inputBg: inputBg ?? this.inputBg,
      errorText: errorText ?? this.errorText,
      flameGlow: flameGlow ?? this.flameGlow,
      accentSelectedBg: accentSelectedBg ?? this.accentSelectedBg,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      charcoal: Color.lerp(charcoal, other.charcoal, t)!,
      charcoalLight: Color.lerp(charcoalLight, other.charcoalLight, t)!,
      charcoalDeep: Color.lerp(charcoalDeep, other.charcoalDeep, t)!,
      ember: Color.lerp(ember, other.ember, t)!,
      emberDark: Color.lerp(emberDark, other.emberDark, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      creamMuted: Color.lerp(creamMuted, other.creamMuted, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardBorderStrong: Color.lerp(cardBorderStrong, other.cardBorderStrong, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      flameGlow: Color.lerp(flameGlow, other.flameGlow, t)!,
      accentSelectedBg: Color.lerp(accentSelectedBg, other.accentSelectedBg, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.emberTheme;
}
