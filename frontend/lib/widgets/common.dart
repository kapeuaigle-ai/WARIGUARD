/// Widgets partagés — style du prototype : cartes blanches à bord doux,
/// badges pill, jauge, icône bouclier vert arrondi.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class WgCard extends StatelessWidget {
  const WgCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Wg.surface,
        borderRadius: BorderRadius.circular(Wg.radius),
        border: Border.all(color: borderColor ?? Wg.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Wg.radius),
        child: card,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall),
      );
}

/// Badge pill plein, comme « ! RISQUE ÉLEVÉ » du prototype.
class RiskBadge extends StatelessWidget {
  const RiskBadge(this.level, {super.key, this.compact = false});

  final RiskLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Wg.riskColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14, vertical: compact ? 4 : 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level == RiskLevel.vert
                ? Icons.check_rounded
                : Icons.priority_high_rounded,
            size: compact ? 11 : 13,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            Wg.riskLabel(level),
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Jauge semi-circulaire du score de risque.
class RiskGauge extends StatelessWidget {
  const RiskGauge({super.key, required this.score, required this.level, this.size = 168});

  final double score;
  final RiskLevel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size * 0.62,
        child: CustomPaint(
          painter: _GaugePainter(value: value, color: Wg.riskColor(level)),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(value * 100).round()}',
                    style: TextStyle(
                      fontSize: size * 0.21,
                      fontWeight: FontWeight.w800,
                      color: Wg.riskColor(level),
                      height: 1,
                    )),
                Text('SCORE DE RISQUE / 100',
                    style: TextStyle(
                        fontSize: size * 0.05,
                        letterSpacing: 1.6,
                        color: Wg.textFaint,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = math.min(size.width / 2, size.height) - 6;
    const start = math.pi;
    const sweep = math.pi;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = Wg.surfaceAlt;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), start, sweep, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
        sweep * value.clamp(0.001, 1.0), false, arc);

    for (final t in [0.35, 0.65]) {
      final angle = start + sweep * t;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 12);
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 8);
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = Wg.borderStrong
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value || old.color != color;
}

/// Carte statistique du prototype : pastille d'icône, grand chiffre, libellé.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon = Icons.shield_rounded,
    this.accent = Wg.green,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return WgCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Wg.text)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Wg.textDim,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Icône bouclier : carré arrondi vert, bouclier blanc (logo du prototype).
class ShieldMark extends StatelessWidget {
  const ShieldMark({super.key, this.size = 34, this.color = Wg.green});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.verified_user_rounded,
          size: size * 0.55, color: Colors.white),
    );
  }
}

/// Pastille circulaire teintée avec icône (permissions, alertes du prototype).
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    this.color = Wg.green,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.45, color: color),
    );
  }
}
