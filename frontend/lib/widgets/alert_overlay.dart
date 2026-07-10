/// Pop-up d'alerte — « l'écran roi » du cahier des charges. Reproduction
/// exacte du prototype : en-tête de risque, déclencheurs, trois actions
/// empilées (Raccrocher / Signaler / Continuer). Les chips « Bouclier Texte »
/// et « Bouclier Lien » indiquent, de façon minimale, quel bouclier a détecté
/// la menace.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Couche d'alerte : voile sombre + feuille ancrée en bas. Rendue à
/// l'intérieur de l'écran de l'app, donc affichée par-dessus n'importe quel
/// onglet et par-dessus la barre de navigation (§3.2).
class AlertOverlayLayer extends StatelessWidget {
  const AlertOverlayLayer({super.key, required this.alert, required this.onResolve});

  final AlertRecord alert;

  /// null = fermé sans décision (bouton ×).
  final ValueChanged<AlertStatus?> onResolve;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => onResolve(null),
                  child: const ColoredBox(color: Color(0x8C0F1214)),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 14, end: 0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, dy, child) =>
                      Transform.translate(offset: Offset(0, dy), child: child),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: constraints.maxHeight * 0.95),
                    child: _AlertBody(alert: alert, onResolve: onResolve),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBody extends StatelessWidget {
  const _AlertBody({required this.alert, required this.onResolve});

  final AlertRecord alert;
  final ValueChanged<AlertStatus?> onResolve;

  bool get _isCall => alert.channel == MessageChannel.appel;

  String get _title => switch (alert.riskLevel) {
        RiskLevel.rouge => 'Arnaque probable détectée',
        RiskLevel.orange => 'Message suspect à vérifier',
        RiskLevel.vert => 'Aucune menace détectée',
      };

  IconData get _glyph => switch (alert.riskLevel) {
        RiskLevel.rouge => Icons.gpp_bad_rounded,
        RiskLevel.orange => Icons.gpp_maybe_rounded,
        RiskLevel.vert => Icons.gpp_good_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = Wg.riskColor(alert.riskLevel);
    final tint = switch (alert.riskLevel) {
      RiskLevel.rouge => Wg.redTint,
      RiskLevel.orange => Wg.orangeTint,
      RiskLevel.vert => Wg.greenTint,
    };
    final subtitle = _isCall
        ? 'Appel en cours · « $_shortTitle »'
        : 'SMS reçu · « $_shortTitle »';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Wg.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
          22, 26, 22, 22 + MediaQuery.viewPaddingOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton fermer
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => onResolve(null),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                      color: Wg.borderSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 20, color: Wg.textDim),
                ),
              ),
            ),
            // En-tête de risque
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(_glyph, size: 42, color: color),
            ),
            const SizedBox(height: 14),
            RiskPill(alert.riskLevel),
            const SizedBox(height: 14),
            Text(_title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Wg.textDim, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            // Boucliers ayant détecté (demande : Bouclier Texte / Bouclier Lien)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [for (final s in alert.shields) ShieldChip(s)],
            ),
            const SizedBox(height: 20),
            // Déclencheurs
            if (alert.triggers.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Wg.subtleAlt,
                  border: Border.all(color: Wg.borderSofter),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (var i = 0; i < alert.triggers.length; i++)
                      Container(
                        decoration: BoxDecoration(
                          border: i == alert.triggers.length - 1
                              ? null
                              : const Border(
                                  bottom: BorderSide(color: Wg.borderSoft)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(
                          children: [
                            Icon(_triggerIcon(alert.triggers[i]),
                                size: 20, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(alert.triggers[i],
                                  style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            // Actions
            _PrimaryAction(
              color: color,
              icon: _isCall ? Icons.call_end_rounded : Icons.delete_rounded,
              label: _isCall ? 'Raccrocher' : 'Supprimer le SMS',
              onTap: () => onResolve(AlertStatus.blocked),
            ),
            const SizedBox(height: 10),
            _SecondaryAction(
              icon: Icons.flag_rounded,
              label: 'Signaler cette arnaque',
              onTap: () => onResolve(AlertStatus.reported),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: TextButton(
                onPressed: () => onResolve(AlertStatus.ignored),
                child: Text(_isCall ? "Continuer l'appel" : 'Garder le SMS',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A949B))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _shortTitle {
    final m = RegExp(r'«\s*(.+?)\s*»').firstMatch(alert.title);
    return m != null ? m.group(1)! : alert.title;
  }

  static IconData _triggerIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('code')) return Icons.password_rounded;
    if (c.contains('usurpation') || c.contains('agent') || c.contains('opérateur')) {
      return Icons.person_off_rounded;
    }
    if (c.contains('lien') || c.contains('url') || c.contains('clic')) {
      return Icons.link_off_rounded;
    }
    if (c.contains('gain') || c.contains('lot') || c.contains('frais') ||
        c.contains('loterie')) {
      return Icons.redeem_rounded;
    }
    if (c.contains('erreur') || c.contains('remboursement') || c.contains('renvoi') ||
        c.contains('transfert')) {
      return Icons.currency_exchange_rounded;
    }
    return Icons.error_rounded;
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Wg.orangeTint,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Wg.orangeDeep),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Wg.orangeDeep)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lance la simulation : analyse réelle → pop-up affiché par-dessus l'app.
Future<void> runSimulatedAlert(BuildContext context) =>
    context.read<AppState>().triggerSimulatedAlert();

String alertResolutionMessage(AlertStatus status) => switch (status) {
      AlertStatus.blocked => 'Appel raccroché — menace bloquée.',
      AlertStatus.reported => 'Merci ! Menace signalée à la communauté.',
      AlertStatus.ignored => 'Appel poursuivi. Restez vigilant.',
    };
