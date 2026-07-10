/// Paramètres (cahier des charges §3.4) : mode de protection (auto / à la
/// demande), autoriser l'analyse, permissions, langue. Chaque toggle affiche
/// un texte explicite (accessibilité). Accès discret aux données & au moteur.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'data_privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showData = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings;

    if (_showData) {
      return DataPrivacyScreen(onBack: () => setState(() => _showData = false));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 20),
            child: Text('Paramètres',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26)),
          ),

          if (s.permMissing)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(
                  color: Wg.orangeTint,
                  border: Border.all(color: Wg.orangeTintBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning_rounded, size: 22, color: Wg.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Autorisation manquante',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Wg.orangeDark)),
                          SizedBox(height: 2),
                          Text(
                            'Activez les autorisations ci-dessous pour une protection complète.',
                            style: TextStyle(
                                fontSize: 12.5, height: 1.4, color: Wg.orangeDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Protection
          const SectionLabel('Protection'),
          _Group(children: [
            ToggleRow(
              title: 'Mode de protection',
              subtitle: s.mode == ProtectionMode.automatique
                  ? 'Automatique — activé'
                  : 'À la demande',
              value: s.mode == ProtectionMode.automatique,
              onChanged: (v) => state.setMode(
                  v ? ProtectionMode.automatique : ProtectionMode.aLaDemande),
            ),
            _divider,
            ToggleRow(
              title: "Autoriser l'analyse",
              subtitle: s.allowAnalysis ? 'Activé' : 'Désactivé',
              value: s.allowAnalysis,
              onChanged: (_) => state.toggleAnalysis(),
            ),
          ]),
          const SizedBox(height: 22),

          // Autorisations
          const SectionLabel('Autorisations'),
          _Group(children: [
            ToggleRow(
              leading: Icons.mic_none_rounded,
              title: 'Microphone',
              subtitle: s.micGranted ? 'Accordé' : 'Refusé',
              value: s.micGranted,
              onChanged: (_) => state.toggleMic(),
            ),
            _divider,
            ToggleRow(
              leading: Icons.layers_outlined,
              title: "Superposition d'écran",
              subtitle: s.overlayGranted ? 'Accordé' : 'Refusé',
              value: s.overlayGranted,
              onChanged: (_) => state.toggleOverlay(),
            ),
          ]),
          const SizedBox(height: 22),

          // Langue
          const SectionLabel('Langue'),
          WgCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: const [
                Icon(Icons.translate_rounded, size: 22, color: Wg.text),
                SizedBox(width: 14),
                Expanded(
                    child: Text('Langue',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                Text('Français',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Wg.textDim)),
                SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, size: 20, color: Wg.textDim),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Confidentialité & données (preuve AES + chiffres réels)
          const SectionLabel('Confidentialité & données'),
          WgCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _NavRow(
                  icon: Icons.lock_rounded,
                  title: 'Données locales & chiffrement',
                  subtitle: 'AES-256 · sur l\'appareil',
                  onTap: () => setState(() => _showData = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _divider = Divider(height: 1, color: Wg.borderSoft);
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Wg.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (final child in children)
            child is Divider
                ? child
                : Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Wg.green),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12.5, color: Wg.textDim)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Wg.chevron),
          ],
        ),
      ),
    );
  }
}
