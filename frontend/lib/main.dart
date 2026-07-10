import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/permissions_screen.dart';
import 'screens/shell.dart';
import 'screens/welcome_screen.dart';
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
      title: 'WariGuard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _permissionsStep = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.ready) return const _Splash();

    Widget child;
    if (state.settings.onboarded) {
      child = const AppShell();
    } else if (_permissionsStep) {
      child = const Scaffold(
        backgroundColor: Wg.bg,
        body: SafeArea(child: PermissionsScreen()),
      );
    } else {
      child = Scaffold(
        backgroundColor: Wg.bg,
        body: SafeArea(
          child: WelcomeScreen(
              onContinue: () => setState(() => _permissionsStep = true)),
        ),
      );
    }

    return _PhoneFrame(child: child);
  }
}

/// Cadre téléphone sur grand écran (384×832, comme le prototype), plein écran
/// sur mobile. La barre d'état factice n'apparaît que dans le cadre.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) return child;
        return ColoredBox(
          color: Wg.stage,
          child: Center(
            child: Container(
              width: 384,
              height: 832,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Wg.device,
                borderRadius: BorderRadius.circular(46),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101814).withValues(alpha: 0.34),
                    blurRadius: 80,
                    spreadRadius: -24,
                    offset: const Offset(0, 40),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Material(
                  color: Wg.bg,
                  child: Column(
                    children: [
                      const _StatusBar(),
                      Expanded(
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Padding(
        padding: EdgeInsets.fromLTRB(26, 0, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('9:41',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Wg.text)),
            Row(
              children: [
                Icon(Icons.signal_cellular_alt_rounded, size: 16, color: Wg.text),
                SizedBox(width: 6),
                Icon(Icons.wifi_rounded, size: 16, color: Wg.text),
                SizedBox(width: 6),
                Icon(Icons.battery_full_rounded, size: 18, color: Wg.text),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Wg.bg,
      body: Center(child: ShieldMark(size: 64)),
    );
  }
}
