/// À propos (cahier des charges §3.5) : mission, confidentialité, support,
/// FAQ. Écran entièrement statique, aucune logique conditionnelle.
library;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _faq = [
    (
      'WariGuard écoute-t-il mes appels ?',
      "L'analyse se fait sur l'appareil, uniquement pendant un appel suspect. Aucun enregistrement n'est conservé.",
    ),
    (
      'Est-ce que ça fonctionne hors ligne ?',
      'Oui, la détection des menaces les plus courantes fonctionne sans connexion internet.',
    ),
    (
      'Est-ce gratuit ?',
      'La protection de base est entièrement gratuite pour tous les utilisateurs.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 22),
            child: Column(
              children: const [
                ShieldMark(size: 64),
                SizedBox(height: 14),
                Text('WariGuard',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Version 1.0.0 · MVP',
                    style: TextStyle(fontSize: 12.5, color: Wg.textFaint)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'WariGuard protège les utilisateurs de Mobile Money contre le phishing '
              'vocal et les arnaques par SMS. Notre mission : rendre chaque transaction '
              "plus sûre en Afrique de l'Ouest, en détectant les fraudes avant qu'elles "
              "ne coûtent de l'argent.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.6, color: Wg.textMid),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Wg.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _LinkRow(
                  icon: Icons.shield_outlined,
                  label: 'Politique de confidentialité',
                  onTap: () => _toast(context, 'Politique de confidentialité'),
                ),
                const Divider(height: 1, color: Wg.borderSoft),
                _LinkRow(
                  icon: Icons.support_agent_rounded,
                  label: 'Contacter le support',
                  onTap: () => _toast(context, 'Support : support@wariguard.ci'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionLabel('Questions fréquentes'),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Wg.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _faq.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Wg.borderSoft),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_faq[i].$1,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(_faq[i].$2,
                            style: const TextStyle(
                                fontSize: 13, height: 1.5, color: Wg.textDim)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Wg.textDim),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Wg.chevron),
          ],
        ),
      ),
    );
  }
}
