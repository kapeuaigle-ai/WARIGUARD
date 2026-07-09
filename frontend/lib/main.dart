import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding_screen.dart';
import 'screens/shell.dart';
import 'services/app_state.dart';
import 'theme.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const WariGuardApp(),
    ),
  );
}

class WariGuardApp extends StatelessWidget {
  const WariGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WariGuard — Bouclier Mobile Money',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.ready) return const _Splash();

    // Cadre « téléphone » centré sur grand écran, plein écran sur mobile.
    final child = state.consent.onboarded ? const AppShell() : const OnboardingScreen();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) return child;
        return ColoredBox(
          color: Wg.bgDeep,
          child: Center(
            child: Container(
              width: 430,
              height: constraints.maxHeight.clamp(0, 900).toDouble(),
              margin: const EdgeInsets.symmetric(vertical: 24),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Wg.borderHi, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Wg.teal.withValues(alpha: 0.08),
                    blurRadius: 80,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShieldMark(size: 64),
            SizedBox(height: 20),
            Text('WariGuard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Chargement du bouclier…', style: TextStyle(color: Wg.textDim)),
          ],
        ),
      ),
    );
  }
}
