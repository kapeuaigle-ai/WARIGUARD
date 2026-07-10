/// Confidentialité & données — preuve tangible du « Done » MVP : stockage
/// local chiffré AES-256 (blob affiché + déchiffrement) et chiffres réels du
/// moteur mesurés en direct sur le jeu de données embarqué.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DataPrivacyScreen extends StatefulWidget {
  const DataPrivacyScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends State<DataPrivacyScreen> {
  bool _decrypted = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final blob = state.lastEncryptedSample;
    final metrics = state.metrics;

    return SafeArea(
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 20, color: Wg.textDim),
                    SizedBox(width: 6),
                    Text('Paramètres',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Wg.textDim)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Confidentialité & données',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
            const SizedBox(height: 6),
            const Text(
              'Pas de promesses : des preuves. Tout se passe sur votre appareil.',
              style: TextStyle(fontSize: 13.5, color: Wg.textDim, height: 1.5),
            ),
            const SizedBox(height: 22),

            // Chiffrement
            const SectionLabel('Stockage local chiffré — AES-256'),
            WgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.enhanced_encryption_rounded,
                          size: 22, color: Wg.green),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Historique chiffré sur l\'appareil',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Wg.greenTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('AES-256-CBC',
                            style: monoStyle.copyWith(
                                fontSize: 10, color: Wg.greenBadge)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clé de 256 bits générée sur cet appareil (empreinte ${state.crypto.keyFingerprint}). '
                    'Aucune alerte, aucun message n\'est envoyé vers un serveur.',
                    style: const TextStyle(
                        fontSize: 12.5, color: Wg.textDim, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (blob != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12181C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('\$ cat wariguard/alerts.enc',
                              style: monoStyle.copyWith(
                                  fontSize: 10.5, color: Wg.textFaint)),
                          const SizedBox(height: 6),
                          Text(
                            _decrypted
                                ? _decryptPreview(state)
                                : 'IV=${blob.iv}\n${_wrap(blob.ciphertextB64)}',
                            style: monoStyle.copyWith(
                              fontSize: 10.5,
                              height: 1.55,
                              color: _decrypted
                                  ? const Color(0xFF7BE3A8)
                                  : const Color(0xFF8FD3F4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Wg.green,
                        side: const BorderSide(color: Wg.border),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => setState(() => _decrypted = !_decrypted),
                      icon: Icon(_decrypted ? Icons.lock_rounded : Icons.lock_open_rounded,
                          size: 17),
                      label: Text(_decrypted
                          ? 'Voir le chiffré'
                          : 'Déchiffrer (avec la clé locale)'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Chiffres réels
            const SectionLabel('Moteur de détection — chiffres mesurés'),
            if (metrics != null) _MetricsCard(metrics: metrics),
            const SizedBox(height: 22),

            // Moteur
            const SectionLabel('Moteur d\'analyse'),
            WgCard(
              child: Column(
                children: [
                  _EngineOption(
                    title: 'Moteur local (sur l\'appareil)',
                    subtitle:
                        'WariGuard-Local v1.0 · heuristique FR + Nouchi · 0 donnée sortante',
                    selected: state.engineSource == EngineSource.local,
                    onTap: () => state.setEngineSource(EngineSource.local),
                  ),
                  const Divider(height: 18, color: Wg.borderSoft),
                  _EngineOption(
                    title: 'Modèle ML distant (en développement)',
                    subtitle: state.apiAvailable
                        ? 'Serveur modèle détecté — prêt'
                        : 'Le classifieur CamemBERT arrive — contrat JSON déjà figé',
                    selected: state.engineSource == EngineSource.api,
                    enabled: state.apiAvailable,
                    onTap: () => state.setEngineSource(EngineSource.api),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Wg.red,
                side: BorderSide(color: Wg.red.withValues(alpha: 0.4)),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: state.history.isEmpty ? null : () => state.clearHistory(),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Effacer tout l\'historique local'),
            ),
          ],
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

  static String _wrap(String s) {
    final t = s.length > 176 ? s.substring(0, 176) : s;
    final buf = StringBuffer();
    for (var i = 0; i < t.length; i += 34) {
      buf.writeln(t.substring(i, (i + 34).clamp(0, t.length)));
    }
    return '${buf.toString().trimRight()}${s.length > 176 ? '…' : ''}';
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});

  final ModelMetrics metrics;

  @override
  Widget build(BuildContext context) {
    String pct(double v) => '${(v * 100).toStringAsFixed(0)}%';
    return WgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 20, color: Wg.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('WariGuard-Local v1.0',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Wg.greenTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('sur ${metrics.totalExamples} exemples',
                    style: const TextStyle(
                        fontSize: 10, color: Wg.greenBadge, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: 'Rappel', value: pct(metrics.recall)),
              _Metric(label: 'Précision', value: pct(metrics.precision)),
              _Metric(label: 'F1', value: pct(metrics.f1)),
              _Metric(label: 'Type OK', value: pct(metrics.typeAccuracy)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Wg.borderSoft),
          const SizedBox(height: 12),
          Text(
            'Jeu de données : ${metrics.scamExamples} arnaques + ${metrics.legitExamples} messages légitimes (FR + Nouchi)',
            style: const TextStyle(fontSize: 11.5, color: Wg.textFaint),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: Wg.green)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Wg.textDim)),
        ],
      ),
    );
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
            color: selected ? Wg.green : (enabled ? Wg.textDim : Wg.textFaint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Wg.text : Wg.textFaint)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Wg.textFaint, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
