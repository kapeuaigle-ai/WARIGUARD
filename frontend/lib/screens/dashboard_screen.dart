/// Accueil — layout exact du prototype : hero « Protection active » vert pâle
/// avec interrupteur, cartes statistiques, bouton pointillé « Simuler un appel
/// suspect », complété par les chiffres réels du moteur (exigence MVP).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/alert_sheet.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _simulateCall(BuildContext context) async {
    final state = context.read<AppState>();
    if (!state.protectionActive) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Activez d\'abord la protection.'),
      ));
      return;
    }
    final scenario = state.dataset.examples
        .firstWhere((e) => e.label == ScamType.fauxAgent && e.channel == MessageChannel.appel);
    final result = await state.analyzeText(scenario.text, scenario.channel);
    if (!context.mounted) return;
    await AlertSheet.show(
      context,
      result: result,
      channel: scenario.channel,
      sourceLabel: 'Appel en cours · « Agent Wave — vérification »',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final metrics = state.metrics;
    final active = state.protectionActive;
    final last = state.history.isEmpty ? null : state.history.first.timestamp;
    final lastLabel = last == null
        ? '—'
        : '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Wg.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            // ---- En-tête (logo + nom, comme le prototype) ----
            const Row(
              children: [
                ShieldMark(size: 34),
                SizedBox(width: 10),
                Text('WariGuard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 18),

            // ---- Hero « Protection active » ----
            Container(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              decoration: BoxDecoration(
                color: active ? Wg.greenTint : Wg.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  ShieldMark(size: 88, color: active ? Wg.green : Wg.textFaint),
                  const SizedBox(height: 20),
                  Text(
                    active ? 'Protection active' : 'Protection désactivée',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: active ? Wg.greenDark : Wg.textDim,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    active
                        ? 'WariGuard surveille vos appels et SMS\nen temps réel.'
                        : 'Réactivez la protection pour être\ncouvert en temps réel.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Wg.textDim, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Protection',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 15)),
                              Text(active ? 'Activée' : 'Désactivée',
                                  style: const TextStyle(
                                      fontSize: 12.5, color: Wg.textDim)),
                            ],
                          ),
                        ),
                        Switch(
                          value: active,
                          onChanged: (v) =>
                              context.read<AppState>().setProtection(v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---- Statistiques (2 cartes comme le prototype) ----
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '${state.threatsBlocked}',
                    label: 'Menaces détectées',
                    icon: Icons.block_rounded,
                    accent: Wg.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    value: lastLabel,
                    label: 'Dernière analyse',
                    icon: Icons.schedule_rounded,
                    accent: Wg.textDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ---- Simulateur (bouton pointillé du prototype) ----
            _DashedButton(
              onTap: () => _simulateCall(context),
              icon: Icons.play_circle_rounded,
              label: 'Simuler un appel suspect',
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Mode démo — pour la présentation',
                  style: TextStyle(fontSize: 11.5, color: Wg.textFaint)),
            ),
            const SizedBox(height: 22),

            // ---- Chiffres réels du moteur (exigence MVP) ----
            const SectionLabel('Moteur de détection — chiffres mesurés'),
            if (metrics != null) _MetricsCard(metrics: metrics),
            const SizedBox(height: 20),

            // ---- Historique ----
            const SectionLabel('Dernières analyses'),
            if (state.history.isEmpty)
              const WgCard(
                child: Row(
                  children: [
                    Icon(Icons.inbox_rounded, color: Wg.textFaint),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucune analyse pour l\'instant. Simulez un appel ou testez un scénario dans Text Shield.',
                        style: TextStyle(color: Wg.textDim, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...state.history.take(6).map((h) => _HistoryTile(entry: h)),
          ],
        ),
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.onTap, required this.icon, required this.label});

  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Wg.text),
              const SizedBox(width: 9),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: Wg.text)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Wg.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(18));
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
              const Icon(Icons.psychology_rounded, color: Wg.green, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('WariGuard-Local v1.0',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Wg.greenTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('évalué sur ${metrics.totalExamples} exemples',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Wg.greenDark,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: 'Rappel', value: pct(metrics.recall), hint: 'arnaques détectées'),
              _Metric(label: 'Précision', value: pct(metrics.precision), hint: 'alertes justifiées'),
              _Metric(label: 'F1', value: pct(metrics.f1), hint: 'équilibre global'),
              _Metric(label: 'Type OK', value: pct(metrics.typeAccuracy), hint: 'bon diagnostic'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Jeu de données : ${metrics.scamExamples} arnaques + ${metrics.legitExamples} messages légitimes (FR + Nouchi)',
            style: const TextStyle(fontSize: 11.5, color: Wg.textFaint),
          ),
          const SizedBox(height: 10),
          _TypeBars(counts: metrics.countsByType),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.hint});

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: Wg.green)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Wg.text)),
          Text(hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8.5, color: Wg.textFaint)),
        ],
      ),
    );
  }
}

class _TypeBars extends StatelessWidget {
  const _TypeBars({required this.counts});

  final Map<ScamType, int> counts;

  static const _order = [
    ScamType.fauxAgent,
    ScamType.fauxGain,
    ScamType.transfertErrone,
    ScamType.phishingLien,
    ScamType.aucun,
  ];

  @override
  Widget build(BuildContext context) {
    final maxCount =
        counts.values.isEmpty ? 1 : counts.values.reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final type in _order)
          if (counts.containsKey(type))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      type == ScamType.aucun ? 'Légitime' : type.label,
                      style: const TextStyle(fontSize: 10.5, color: Wg.textDim),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: counts[type]! / maxCount,
                        minHeight: 7,
                        backgroundColor: Wg.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation(
                          type == ScamType.aucun ? Wg.green : Wg.orange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    child: Text('${counts[type]}',
                        textAlign: TextAlign.right,
                        style:
                            const TextStyle(fontSize: 10.5, color: Wg.textFaint)),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = Wg.riskColor(entry.riskLevel);
    final time =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WgCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Wg.riskTint(entry.riskLevel),
                shape: BoxShape.circle,
              ),
              child: Icon(
                entry.channel == MessageChannel.sms
                    ? Icons.sms_rounded
                    : Icons.phone_rounded,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.textPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.scamType == ScamType.aucun ? "Aucune menace" : entry.scamType.label} · $time',
                    style: const TextStyle(fontSize: 10.5, color: Wg.textFaint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            RiskBadge(entry.riskLevel, compact: true),
          ],
        ),
      ),
    );
  }
}
