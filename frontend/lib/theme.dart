/// Identité visuelle WariGuard — navy profond + teal « bouclier »,
/// alertes rouge / orange / vert comme langage central de l'app.
library;

import 'package:flutter/material.dart';

import 'models.dart';

abstract final class Wg {
  // Fond
  static const bg = Color(0xFF06111F);
  static const bgDeep = Color(0xFF040B15);
  static const surface = Color(0xFF0C1E33);
  static const surfaceHi = Color(0xFF12293F);
  static const border = Color(0x1F4EE6C5);
  static const borderHi = Color(0x3D2EE6C5);

  // Marque
  static const teal = Color(0xFF2EE6C5);
  static const tealDim = Color(0xFF17907B);
  static const cyan = Color(0xFF4EA8DE);

  // Texte
  static const text = Color(0xFFEAF4F2);
  static const textDim = Color(0xFF8FA8B5);
  static const textFaint = Color(0xFF5A7180);

  // Alertes
  static const red = Color(0xFFFF5D5D);
  static const orange = Color(0xFFFFB454);
  static const green = Color(0xFF3DDC97);

  static Color riskColor(RiskLevel level) => switch (level) {
        RiskLevel.rouge => red,
        RiskLevel.orange => orange,
        RiskLevel.vert => green,
      };

  static String riskLabel(RiskLevel level) => switch (level) {
        RiskLevel.rouge => 'DANGER',
        RiskLevel.orange => 'MÉFIANCE',
        RiskLevel.vert => 'SÛR',
      };

  static const radius = 20.0;
}

ThemeData buildTheme() {
  const fontBody = 'Sora';
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: fontBody,
    scaffoldBackgroundColor: Wg.bg,
    colorScheme: const ColorScheme.dark(
      primary: Wg.teal,
      onPrimary: Color(0xFF04241E),
      secondary: Wg.cyan,
      surface: Wg.surface,
      onSurface: Wg.text,
      error: Wg.red,
    ),
  );

  final t = base.textTheme.apply(bodyColor: Wg.text, displayColor: Wg.text);
  return base.copyWith(
    textTheme: t.copyWith(
      headlineMedium: t.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
      titleLarge:
          t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: t.bodyMedium?.copyWith(color: Wg.textDim, height: 1.5),
      labelSmall: t.labelSmall?.copyWith(
          color: Wg.textFaint, letterSpacing: 1.4, fontWeight: FontWeight.w600),
    ),
    dividerColor: Wg.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Wg.bgDeep,
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
        borderSide: const BorderSide(color: Wg.teal, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Wg.teal,
        foregroundColor: const Color(0xFF04241E),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: fontBody),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Wg.teal,
        side: const BorderSide(color: Wg.borderHi),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: fontBody),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? const Color(0xFF04241E) : Wg.textFaint),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Wg.teal : Wg.bgDeep),
      trackOutlineColor: WidgetStateProperty.all(Wg.border),
    ),
  );
}

const monoStyle = TextStyle(fontFamily: 'IBM Plex Mono');
