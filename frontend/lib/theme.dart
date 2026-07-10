/// Identité visuelle WariGuard — reprise exacte du prototype mobile Android
/// (WariGuard.dc.html) : thème clair, Manrope, vert #0E7A55, cartes blanches
/// à bord doux #E7EAEC, alertes rouge / orange, icônes arrondies modernes.
library;

import 'package:flutter/material.dart';

import 'models.dart';

abstract final class Wg {
  // Fonds
  static const stage = Color(0xFFECEEEF);
  static const device = Color(0xFF0D0F10);
  static const bg = Color(0xFFFFFFFF);
  static const subtle = Color(0xFFF6F7F8);
  static const subtleAlt = Color(0xFFFBFCFC);

  // Bords
  static const border = Color(0xFFE7EAEC);
  static const borderSoft = Color(0xFFF1F3F4);
  static const borderSofter = Color(0xFFEEF1F2);
  static const trackOff = Color(0xFFD2D7DA);
  static const chevron = Color(0xFFC0C7CB);

  // Vert (marque)
  static const green = Color(0xFF0E7A55);
  static const greenDark = Color(0xFF0B5E43);
  static const greenBadge = Color(0xFF0B6E4F);
  static const greenTint = Color(0xFFE7F2EC);
  static const greenTintBorder = Color(0xFFCFE6DA);
  static const greenRing = Color(0xFFD3E8DC);

  // Texte
  static const text = Color(0xFF12181C);
  static const textMid = Color(0xFF3D464C);
  static const textDim = Color(0xFF5C666D);
  static const textFaint = Color(0xFF97A0A6);
  static const iconMuted = Color(0xFF98A0A6);

  // Rouge
  static const red = Color(0xFFDC2626);
  static const redTint = Color(0xFFFDECEC);

  // Orange
  static const orange = Color(0xFFE8760C);
  static const orangeDeep = Color(0xFFB85C05);
  static const orangeDark = Color(0xFF8A4B04);
  static const orangeTint = Color(0xFFFCEFE1);
  static const orangeTintBorder = Color(0xFFF5D9BC);
  static const orangeRing = Color(0xFFF7E0C8);

  static Color riskColor(RiskLevel level) => switch (level) {
        RiskLevel.rouge => red,
        RiskLevel.orange => orange,
        RiskLevel.vert => green,
      };

  static String riskWord(RiskLevel level) => switch (level) {
        RiskLevel.rouge => 'ÉLEVÉ',
        RiskLevel.orange => 'MOYEN',
        RiskLevel.vert => 'FAIBLE',
      };
}

ThemeData buildTheme() {
  const font = 'Manrope';
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: font,
    scaffoldBackgroundColor: Wg.bg,
    splashFactory: InkRipple.splashFactory,
    colorScheme: const ColorScheme.light(
      primary: Wg.green,
      onPrimary: Colors.white,
      secondary: Wg.orange,
      surface: Wg.bg,
      onSurface: Wg.text,
      error: Wg.red,
    ),
  );

  final t = base.textTheme.apply(bodyColor: Wg.text, displayColor: Wg.text);
  return base.copyWith(
    textTheme: t.copyWith(
      headlineMedium: t.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.2),
      titleLarge:
          t.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: t.bodyMedium?.copyWith(color: Wg.textDim, height: 1.5),
      labelSmall: t.labelSmall?.copyWith(
          color: Wg.textFaint, letterSpacing: 1.3, fontWeight: FontWeight.w800),
    ),
    dividerColor: Wg.borderSoft,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Wg.text,
      contentTextStyle: TextStyle(color: Colors.white, fontFamily: font),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Style « code » monospace, conservé pour la preuve de chiffrement AES.
const monoStyle = TextStyle(fontFamily: 'IBM Plex Mono');
