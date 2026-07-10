/// Accueil (cahier des charges §3.1) : bouclier d'état, toggle protection,
/// résumé (dernière analyse, nb de menaces), bouton démo « Simuler un appel ».
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/alert_overlay.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onFixPermission});

  final VoidCallback onFixPermission;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings;
    final on = s.protectionOn;
    final permMissing = s.permMissing;

    // Palette de la carte d'état selon protégé / permission manquante / off.
    final (cardBg, cardBorder, ring, iconBg, glyph, titleColor, label, sub) = on
        ? (
            Wg.greenTint,
            Wg.greenTintBorder,
            Wg.greenRing,
            Wg.green,
            Icons.verified_user_rounded,
            Wg.greenDark,
            'Protection active',
            'WariGuard surveille vos appels et SMS en temps réel.'
          )
        : permMissing
            ? (
                Wg.orangeTint,
                Wg.orangeTintBorder,
                Wg.orangeRing,
                Wg.orange,
                Icons.gpp_maybe_rounded,
                Wg.orangeDark,
                'Action requise',
                'Autorisez les permissions pour être protégé.'
              )
            : (
                Wg.subtle,
                Wg.border,
                const Color(0xFFE4E8EA),
                Wg.iconMuted,
                Icons.gpp_bad_rounded,
                Wg.text,
                'Protection désactivée',
                "Vous n'êtes pas protégé contre les arnaques."
              );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 18),
            child: Row(
              children: const [
                ShieldMark(size: 28),
                SizedBox(width: 9),
                Text('WariGuard',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1)),
              ],
            ),
          ),

          // Bandeau permission manquante
          if (permMissing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: onFixPermission,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  decoration: BoxDecoration(
                    color: Wg.orangeTint,
                    border: Border.all(color: Wg.orangeTintBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_rounded, size: 22, color: Wg.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Une autorisation manque — vous n'êtes pas entièrement protégé.",
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Wg.orangeDark),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 20, color: Wg.orange),
                    ],
                  ),
                ),
              ),
            ),

          // Carte d'état
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration:
                            BoxDecoration(color: ring, shape: BoxShape.circle),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(26)),
                        child: Icon(glyph, size: 46, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(label,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: titleColor)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 250,
                  child: Text(sub,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13.5, height: 1.5, color: Wg.textDim)),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Protection',
                                style: TextStyle(
                                    fontSize: 14.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 1),
                            Text(s.protection ? 'Activée' : 'Désactivée',
                                style: const TextStyle(
                                    fontSize: 12.5, color: Wg.textDim)),
                          ],
                        ),
                      ),
                      WgToggle(
                        value: s.protection,
                        semanticLabel: 'Protection',
                        onChanged: (_) => state.toggleProtection(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.block_rounded,
                  iconColor: Wg.green,
                  value: '${state.threatsBlocked}',
                  label: 'Menaces détectées',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.schedule_rounded,
                  iconColor: Wg.textDim,
                  value: _shortScan(state.lastScanLabel),
                  label: 'Dernière analyse',
                  valueSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bouton démo
          _DemoButton(onTap: () => runSimulatedAlert(context)),
          const SizedBox(height: 8),
          const Center(
            child: Text('Mode démo — pour la présentation',
                style: TextStyle(fontSize: 11.5, color: Wg.textFaint)),
          ),
        ],
      ),
    );
  }

  static String _shortScan(String s) {
    if (s.contains(',')) return s.split(',').last.trim();
    return s;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueSize = 26,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        border: Border.all(color: Wg.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.15)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12.5, color: Wg.textDim)),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedPainter(),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Wg.subtleAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.play_circle_outline_rounded, size: 20, color: Wg.textDim),
              SizedBox(width: 9),
              Text('Simuler un appel suspect',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9D0D3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(16));
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
