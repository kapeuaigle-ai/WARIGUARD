/// Identité visuelle WariGuard — reprise exacte du prototype WariGuard.html :
/// thème clair, Manrope, vert #0E7A55, cartes blanches à bord doux,
/// alertes rouge / orange / vert en pastilles et badges pill.
library;

import 'package:flutter/material.dart';

import 'models.dart';

abstract final class Wg {
  // Fond
  static const bg = Color(0xFFFFFFFF);
  static const bgPage = Color(0xFFF6F7F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F3F4);
  static const border = Color(0xFFE7EAEC);
  static const borderStrong = Color(0xFFD2D7DA);

  // Marque (vert prototype)
  static const green = Color(0xFF0E7A55);
  static const greenDark = Color(0xFF0B5E43);
  static const greenTint = Color(0xFFE7F2EC);
  static const greenTintStrong = Color(0xFFCFE6DA);

  // Texte
  static const text = Color(0xFF12181C);
  static const textDim = Color(0xFF5C666D);
  static const textFaint = Color(0xFF97A0A6);

  // Alertes
  static const red = Color(0xFFDC2626);
  static const redTint = Color(0xFFFDECEC);
  static const orange = Color(0xFFE8760C);
  static const orangeTint = Color(0xFFFCEFE1);
  static const orangeDark = Color(0xFF8A4B04);

  static Color riskColor(RiskLevel level) => switch (level) {
        RiskLevel.rouge => red,
        RiskLevel.orange => orange,
        RiskLevel.vert => green,
      };

  static Color riskTint(RiskLevel level) => switch (level) {
        RiskLevel.rouge => redTint,
        RiskLevel.orange => orangeTint,
        RiskLevel.vert => greenTint,
      };

  static String riskLabel(RiskLevel level) => switch (level) {
        RiskLevel.rouge => 'RISQUE ÉLEVÉ',
        RiskLevel.orange => 'RISQUE MOYEN',
        RiskLevel.vert => 'AUCUN RISQUE',
      };

  static const radius = 20.0;
}

ThemeData buildTheme() {
  const font = 'Manrope';
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: font,
    scaffoldBackgroundColor: Wg.bg,
    colorScheme: const ColorScheme.light(
      primary: Wg.green,
      onPrimary: Colors.white,
      secondary: Wg.greenDark,
      surface: Wg.surface,
      onSurface: Wg.text,
      error: Wg.red,
    ),
  );

  final t = base.textTheme.apply(bodyColor: Wg.text, displayColor: Wg.text);
  return base.copyWith(
    textTheme: t.copyWith(
      headlineMedium: t.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.18),
      titleLarge:
          t.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: t.bodyMedium?.copyWith(color: Wg.textDim, height: 1.5),
      labelSmall: t.labelSmall?.copyWith(
          color: Wg.textFaint, letterSpacing: 1.4, fontWeight: FontWeight.w700),
    ),
    dividerColor: Wg.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Wg.bgPage,
      hintStyle: const TextStyle(color: Wg.textFaint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Wg.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Wg.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Wg.green, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Wg.green,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontFamily: font, fontSize: 16),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Wg.green,
        side: const BorderSide(color: Wg.borderStrong),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: font),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Wg.textDim,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: font),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Wg.green : Wg.borderStrong),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// Police mono conservée pour les blocs techniques (chiffré AES, refs).
const monoStyle = TextStyle(fontFamily: 'IBM Plex Mono');
