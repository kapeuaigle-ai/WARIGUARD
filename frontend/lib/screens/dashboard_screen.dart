/// Tableau de bord : état de la protection, chiffres réels du moteur
/// (précision / rappel mesurés sur le dataset embarqué) et historique.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final metrics = state.metrics;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9, -1.1),
            radius: 1.5,
            colors: [Color(0xFF0B2C42), Wg.bg],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              // ---- En-tête ----
              Row(
                children: [
                  const ShieldMark(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WariGuard', style: theme.textTheme.titleLarge),
                      Text(
                        state.protectionActive
                            ? 'Protection ${state.consent.mode == ConsentMode.permanent ? "permanente" : "à la demande"}'
                            : 'Protection désactivée',
                        style: TextStyle(
                            fontSize: 12,
                            color: state.protectionActive ? Wg.green : Wg.red),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _StatusDot(active: state.protectionActive),
                ],
              ),
              const SizedBox(height: 24),

              // ---- Bandeau statut ----
              WgCard(
                borderColor:
                    state.protectionActive ? Wg.borderHi : Wg.red.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Icon(
                      state.protectionActive
                          ? Icons.verified_user_rounded
                          : Icons.gpp_bad_rounded,
                      color: state.protectionActive ? Wg.teal : Wg.red,
                      size: 34,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.protectionActive
                                ? 'Votre wari est sous bonne garde'
                                : 'Boucliers éteints',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            state.protectionActive
                                ? 'Text Shield ${state.consent.textShield ? "actif" : "inactif"} · Link Shield ${state.consent.linkShield ? "actif" : "inactif"} · analyse 100% locale'
                                : 'Réactivez la protection depuis l\'écran Sécurité.',
                            style: const TextStyle(fontSize: 12, color: Wg.textDim),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- Stats de session ----
              const SectionLabel('Activité sur cet appareil'),
              Row(
                children: [
                  Expanded(
                      child: StatTile(
                          value: '${state.history.length}', label: 'Analyses')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: StatTile(
                          value: '${state.threatsBlocked}',
                          label: 'Menaces',
                          accent: Wg.red)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: StatTile(
                          value: '${state.warnings}',
                          label: 'Suspects',
                          accent: Wg.orange)),
                ],
              ),
              const SizedBox(height: 20),

              // ---- Chiffres réels du moteur ----
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
                          'Aucune analyse pour l\'instant. Testez un scénario dans Text Shield.',
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
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Wg.green : Wg.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 6),
          Text(active ? 'ON' : 'OFF',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
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
              const Icon(Icons.psychology_rounded, color: Wg.cyan, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('WariGuard-Local v1.0',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Wg.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('évalué sur ${metrics.totalExamples} exemples',
                    style: monoStyle.copyWith(fontSize: 10, color: Wg.cyan)),
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
              style: monoStyle.copyWith(
                  fontSize: 19, fontWeight: FontWeight.w600, color: Wg.teal)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Wg.textDim)),
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
                        backgroundColor: Wg.bgDeep,
                        valueColor: AlwaysStoppedAnimation(
                          type == ScamType.aucun ? Wg.green : Wg.cyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    child: Text('${counts[type]}',
                        textAlign: TextAlign.right,
                        style: monoStyle.copyWith(fontSize: 10.5, color: Wg.textFaint)),
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
            Icon(
              entry.channel == MessageChannel.sms
                  ? Icons.sms_rounded
                  : Icons.phone_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.textPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5)),
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
