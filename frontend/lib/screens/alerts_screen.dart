/// Alertes / Historique (cahier des charges §3.3) : liste triée du plus récent
/// au plus ancien, badge de statut coloré, état vide rassurant. Le détail
/// s'affiche en place (barre de navigation conservée).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selected =
        _selectedId == null ? null : state.history.where((h) => h.id == _selectedId).firstOrNull;

    if (selected != null) {
      return _AlertDetail(
        alert: selected,
        onBack: () => setState(() => _selectedId = null),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child:
                Text('Alertes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26)),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 20),
            child: Text('Historique des menaces détectées',
                style: TextStyle(fontSize: 14, color: Wg.textDim)),
          ),
          if (state.history.isEmpty)
            _EmptyState()
          else
            ...state.history.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AlertRow(
                    alert: a,
                    onTap: () => setState(() => _selectedId = a.id),
                  ),
                )),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: const [
          IconBubble(
              icon: Icons.shield_outlined,
              color: Wg.green,
              bg: Wg.greenTint,
              size: 64,
              radius: 20),
          SizedBox(height: 18),
          Text('Aucune menace pour l’instant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            'Vous êtes protégé. Les alertes détectées apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: Wg.textDim),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.onTap});

  final AlertRecord alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WgCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: Wg.subtle, borderRadius: BorderRadius.circular(13)),
            child: Icon(alert.channel.icon, size: 23, color: Wg.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${alert.typeLabel} · ${alert.relativeDate}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Wg.textDim)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusBadge(alert.status),
        ],
      ),
    );
  }
}

/// Détail d'une alerte — pourquoi détecté, boucliers, conseil, partage.
class _AlertDetail extends StatelessWidget {
  const _AlertDetail({required this.alert, required this.onBack});

  final AlertRecord alert;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_rounded, size: 20, color: Wg.textDim),
                  SizedBox(width: 6),
                  Text('Alertes',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Wg.textDim)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: RiskPill(alert.riskLevel)),
          const SizedBox(height: 14),
          Text(alert.title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.25)),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text('${alert.typeLabel} · ${alert.relativeDate}',
                    style: const TextStyle(fontSize: 13, color: Wg.textDim)),
              ),
              const SizedBox(width: 8),
              StatusBadge(alert.status),
            ],
          ),
          const SizedBox(height: 18),

          // Boucliers (demande : Bouclier Texte / Bouclier Lien)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in alert.shields) ShieldChip(s)],
          ),
          if (alert.linkVerdict == LinkVerdict.bloque) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Wg.redTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_off_rounded, size: 18, color: Wg.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lien bloqué avant ouverture${alert.linkReason != null ? " — ${alert.linkReason!.toLowerCase()}" : ""}',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600, color: Wg.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),

          const SectionLabel('Pourquoi cette détection'),
          ...alert.triggers.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  decoration: BoxDecoration(
                    color: Wg.subtleAlt,
                    border: Border.all(color: Wg.borderSofter),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_rounded, size: 19, color: Wg.red),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 14),

          const SectionLabel('Conseil'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Wg.greenTint,
              border: Border.all(color: Wg.greenTintBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, size: 22, color: Wg.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(alert.advice,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: Wg.greenDark)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Wg.text,
                side: const BorderSide(color: Wg.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Merci ! Partagé avec la communauté WariGuard.')),
              ),
              icon: const Icon(Icons.group_outlined, size: 20, color: Wg.green),
              label: const Text('Partager avec la communauté',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
