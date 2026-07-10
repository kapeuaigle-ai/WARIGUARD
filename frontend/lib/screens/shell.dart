import 'package:flutter/material.dart';

import '../theme.dart';
import 'dashboard_screen.dart';
import 'link_shield_screen.dart';
import 'security_screen.dart';
import 'text_shield_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TextShieldScreen(),
    LinkShieldScreen(),
    SecurityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Wg.bg,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Wg.border)),
        ),
        child: NavigationBar(
          height: 66,
          backgroundColor: Colors.transparent,
          indicatorColor: Wg.greenTint,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Wg.textDim),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Wg.greenDark),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.sms_outlined, color: Wg.textDim),
              selectedIcon: Icon(Icons.sms_rounded, color: Wg.greenDark),
              label: 'Text Shield',
            ),
            NavigationDestination(
              icon: Icon(Icons.link_outlined, color: Wg.textDim),
              selectedIcon: Icon(Icons.link_rounded, color: Wg.greenDark),
              label: 'Link Shield',
            ),
            NavigationDestination(
              icon: Icon(Icons.lock_outline_rounded, color: Wg.textDim),
              selectedIcon: Icon(Icons.lock_rounded, color: Wg.greenDark),
              label: 'Sécurité',
            ),
          ],
        ),
      ),
    );
  }
}
