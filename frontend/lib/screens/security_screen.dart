/// Sécurité & Confidentialité — preuve tangible que les données restent
/// locales et chiffrées (AES-256), gestion du consentement, source du moteur.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'onboarding_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _showDecrypted = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final blob = state.lastEncryptedSample;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text('Sécurité & Confidentialité',
                style: Theme.of(context).textTheme.titleLarge),
            const Text(
              'Pas de promesses : des preuves. Voici ce que WariGuard fait de vos données.',
              style: TextStyle(color: Wg.textDim, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // ---- Consentement ----
            const SectionLabel('Consentement'),
            WgCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fact_check_rounded, color: Wg.green, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.consent.mode.label,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              'Text Shield ${state.consent.textShield ? "✓" : "✗"} · '
                              'Link Shield ${state.consent.linkShield ? "✓" : "✗"} · '
                              'Behavior Shield à venir',
                              style:
                                  const TextStyle(fontSize: 11.5, color: Wg.textDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OnboardingScreen(editMode: true)),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 17),
                      label: const Text('Modifier mon consentement'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Preuve de chiffrement ----
            const SectionLabel('Stockage local chiffré — AES-256'),
            WgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.enhanced_encryption_rounded,
                          color: Wg.green, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Historique chiffré sur l\'appareil',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Wg.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('AES-256-CBC',
                            style: monoStyle.copyWith(fontSize: 10, color: Wg.green)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clé de 256 bits générée sur cet appareil (empreinte ${state.crypto.keyFingerprint}). '
                    'Aucune analyse, aucun message n\'est envoyé vers un serveur.',
                    style: const TextStyle(fontSize: 12.5, color: Wg.textDim, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (blob == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12181C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '// Lancez une analyse dans Text Shield pour générer\n// le premier bloc chiffré.',
                        style: monoStyle.copyWith(fontSize: 11, color: Wg.textFaint),
                      ),
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12181C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Wg.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('\$ cat wariguard/history.enc',
                              style: monoStyle.copyWith(
                                  fontSize: 10.5, color: Wg.textFaint)),
                          const SizedBox(height: 6),
                          Text(
                            _showDecrypted
                                ? _decryptPreview(state)
                                : 'IV=${blob.iv}\n${_wrap(blob.ciphertextB64, 180)}',
                            style: monoStyle.copyWith(
                              fontSize: 10.5,
                              height: 1.55,
                              color: _showDecrypted
                                  ? const Color(0xFF7BE3A8)
                                  : const Color(0xFF8FD3F4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _showDecrypted = !_showDecrypted),
                            icon: Icon(
                                _showDecrypted
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                size: 16),
                            label: Text(_showDecrypted
                                ? 'Voir le chiffré'
                                : 'Déchiffrer (avec la clé locale)'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Moteur d'analyse ----
            const SectionLabel('Moteur d\'analyse'),
            WgCard(
              child: Column(
                children: [
                  _EngineOption(
                    title: 'Moteur local (sur l\'appareil)',
                    subtitle:
                        'WariGuard-Local v1.0 · heuristique FR + Nouchi · 0 donnée sortante',
                    selected: state.engineSource == EngineSource.local,
                    onTap: () =>
                        context.read<AppState>().setEngineSource(EngineSource.local),
                  ),
                  const Divider(height: 18),
                  _EngineOption(
                    title: 'Modèle ML distant (en développement)',
                    subtitle: state.apiAvailable
                        ? 'Serveur modèle détecté sur /api/analyze — prêt'
                        : 'Serveur non détecté · le classifieur CamemBERT arrive — contrat JSON déjà figé',
                    selected: state.engineSource == EngineSource.api,
                    enabled: state.apiAvailable,
                    onTap: () =>
                        context.read<AppState>().setEngineSource(EngineSource.api),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Modèle de menace ----
            const SectionLabel('Ce que WariGuard bloque'),
            const WgCard(
              child: Column(
                children: [
                  _ThreatRow(
                    icon: Icons.record_voice_over_rounded,
                    threat: 'Ingénierie sociale par appel ou SMS',
                    defense: 'Text Shield analyse et alerte en temps réel',
                  ),
                  Divider(height: 18),
                  _ThreatRow(
                    icon: Icons.phishing_rounded,
                    threat: 'Liens de phishing vers de faux portails',
                    defense: 'Link Shield bloque avant le chargement de la page',
                  ),
                  Divider(height: 18),
                  _ThreatRow(
                    icon: Icons.storage_rounded,
                    threat: 'Fuite des données d\'analyse',
                    defense: 'Traitement local + stockage chiffré AES-256',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Danger zone ----
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Wg.red,
                side: BorderSide(color: Wg.red.withValues(alpha: 0.4)),
              ),
              onPressed: state.history.isEmpty
                  ? null
                  : () => context.read<AppState>().clearHistory(),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('Effacer tout l\'historique local'),
            ),
          ],
        ),
      ),
    );
  }

  static String _decryptPreview(AppState state) {
    final entries = state.history.take(2).toList();
    if (entries.isEmpty) return '[]';
    return entries
        .map((e) =>
            '{"risque":"${e.riskLevel.name}","type":"${e.scamType.json}","score":${e.riskScore}}')
        .join('\n');
  }

  static String _wrap(String s, int max) {
    final t = s.length > max ? s.substring(0, max) : s;
    final buf = StringBuffer();
    for (var i = 0; i < t.length; i += 36) {
      buf.writeln(t.substring(i, (i + 36).clamp(0, t.length)));
    }
    return '${buf.toString().trimRight()}${s.length > max ? '…' : ''}';
  }
}

class _EngineOption extends StatelessWidget {
  const _EngineOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 19,
            color: selected
                ? Wg.green
                : enabled
                    ? Wg.textDim
                    : Wg.textFaint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Wg.text : Wg.textFaint)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Wg.textFaint, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatRow extends StatelessWidget {
  const _ThreatRow({required this.icon, required this.threat, required this.defense});

  final IconData icon;
  final String threat;
  final String defense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Wg.surfaceAlt,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: Wg.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(threat,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 11, color: Wg.green),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(defense,
                        style: const TextStyle(fontSize: 11, color: Wg.textDim)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
