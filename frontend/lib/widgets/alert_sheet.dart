/// Feuille d'alerte — reproduction exacte de l'écran « Arnaque probable
/// détectée » du prototype : bouclier teinté, badge pill, signaux listés,
/// action principale rouge, signalement orange pâle, action de repli texte.
library;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AlertSheet {
  static Future<void> show(
    BuildContext context, {
    required AnalysisResult result,
    required MessageChannel channel,
    String? sourceLabel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 406),
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _AlertSheetBody(
        result: result,
        channel: channel,
        sourceLabel: sourceLabel,
      ),
    );
  }
}

class _AlertSheetBody extends StatelessWidget {
  const _AlertSheetBody({
    required this.result,
    required this.channel,
    this.sourceLabel,
  });

  final AnalysisResult result;
  final MessageChannel channel;
  final String? sourceLabel;

  @override
  Widget build(BuildContext context) {
    final color = Wg.riskColor(result.riskLevel);
    final tint = Wg.riskTint(result.riskLevel);
    final danger = result.riskLevel != RiskLevel.vert;
    final isCall = channel == MessageChannel.appel;

    final title = switch (result.riskLevel) {
      RiskLevel.rouge => 'Arnaque probable détectée',
      RiskLevel.orange => 'Message à traiter avec prudence',
      RiskLevel.vert => 'Aucune menace détectée',
    };

    final subtitle = sourceLabel ??
        (isCall ? 'Appel en cours · numéro inconnu' : 'SMS reçu · numéro inconnu');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poignée + fermer
            Row(
              children: [
                const Spacer(),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Wg.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(backgroundColor: Wg.surfaceAlt),
                icon: const Icon(Icons.close_rounded, size: 20, color: Wg.textDim),
              ),
            ),
            // Bouclier teinté
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(
                  danger ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
                  size: 36,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: RiskBadge(result.riskLevel)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Wg.text),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Wg.textDim),
            ),
            const SizedBox(height: 18),
            // Signaux détectés (liste du prototype)
            if (result.triggers.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Wg.bgPage,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Wg.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (var i = 0; i < result.triggers.take(3).length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          children: [
                            Icon(_signalIcon(result.triggers[i].category),
                                size: 19, color: color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _capitalize(result.triggers[i].category),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Wg.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Wg.greenTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  result.explanation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13.5, color: Wg.greenDark, height: 1.5),
                ),
              ),
            const SizedBox(height: 18),
            // Actions
            if (danger) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Wg.red),
                onPressed: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isCall ? Icons.call_end_rounded : Icons.delete_rounded,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(isCall ? 'Raccrocher' : 'Supprimer le SMS'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Wg.orangeTint,
                    foregroundColor: Wg.orangeDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Merci ! Ce signalement renforcera la détection communautaire.'),
                    ));
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Signaler cette arnaque'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isCall ? "Continuer l'appel" : 'Conserver le SMS'),
              ),
            ] else
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Compris'),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _signalIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('code')) return Icons.password_rounded;
    if (c.contains('usurpation') || c.contains('agent')) {
      return Icons.person_off_rounded;
    }
    if (c.contains('urgence') || c.contains('pression') || c.contains('menace')) {
      return Icons.error_rounded;
    }
    if (c.contains('lien') || c.contains('clic')) return Icons.link_off_rounded;
    if (c.contains('gain') || c.contains('lot') || c.contains('frais')) {
      return Icons.redeem_rounded;
    }
    if (c.contains('erreur') || c.contains('remboursement') || c.contains('renvoi')) {
      return Icons.currency_exchange_rounded;
    }
    return Icons.warning_rounded;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
