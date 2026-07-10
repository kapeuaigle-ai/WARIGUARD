/// Coquille de l'app : barre de navigation basse à 4 entrées
/// (Accueil, Alertes, Paramètres, À propos) — pas de navigation profonde.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/alert_overlay.dart';
import 'about_screen.dart';
import 'alerts_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Messenger local : les bandeaux restent dans l'écran de l'app.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> _resolve(AlertStatus? status) async {
    final state = context.read<AppState>();
    await state.dismissAlert(status);
    if (status == null || !mounted) return;
    // Après une décision, on montre l'entrée fraîchement loguée (§3.2).
    setState(() => _index = 1);
    _messengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(alertResolutionMessage(status))));
  }

  @override
  Widget build(BuildContext context) {
    final pendingAlert = context.watch<AppState>().pendingAlert;
    final screens = [
      HomeScreen(onFixPermission: () => setState(() => _index = 2)),
      const AlertsScreen(),
      const SettingsScreen(),
      const AboutScreen(),
    ];

    final scaffold = Scaffold(
      backgroundColor: Wg.bg,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Wg.borderSofter)),
        ),
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
        child: Row(
          children: [
            _NavItem(
              filled: Icons.home_rounded,
              outlined: Icons.home_outlined,
              label: 'Accueil',
              active: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              filled: Icons.notifications_rounded,
              outlined: Icons.notifications_none_rounded,
              label: 'Alertes',
              active: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            _NavItem(
              filled: Icons.settings_rounded,
              outlined: Icons.settings_outlined,
              label: 'Paramètres',
              active: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _NavItem(
              filled: Icons.info_rounded,
              outlined: Icons.info_outline_rounded,
              label: 'À propos',
              active: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
          ],
        ),
      ),
    );

    // Le pop-up d'alerte se superpose à tout, y compris la barre de navigation.
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Stack(
        children: [
          scaffold,
          if (pendingAlert != null)
            AlertOverlayLayer(alert: pendingAlert, onResolve: _resolve),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.filled,
    required this.outlined,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData filled;
  final IconData outlined;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Wg.green : Wg.iconMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? filled : outlined, size: 24, color: color),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
