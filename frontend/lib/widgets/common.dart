/// Widgets partagés : cartes, badges de risque, jauge, en-têtes de section.
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

class RiskBadge extends StatelessWidget {
  const RiskBadge(this.level, {super.key, this.compact = false});

  final RiskLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Wg.riskColor(level);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 3 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6),
            ]),
          ),
          const SizedBox(width: 7),
          Text(
            Wg.riskLabel(level),
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
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
                    style: monoStyle.copyWith(
                      fontSize: size * 0.21,
                      fontWeight: FontWeight.w600,
                      color: Wg.riskColor(level),
                      height: 1,
                    )),
                Text('SCORE DE RISQUE / 100',
                    style: TextStyle(
                        fontSize: size * 0.05,
                        letterSpacing: 1.6,
                        color: Wg.textFaint,
                        fontWeight: FontWeight.w600)),
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
      ..color = Wg.bgDeep;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), start, sweep, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [color.withValues(alpha: 0.25), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
        sweep * value.clamp(0.001, 1.0), false, arc);

    // Graduations seuils orange / rouge
    for (final t in [0.35, 0.65]) {
      final angle = start + sweep * t;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 12);
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 8);
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = Wg.textFaint.withValues(alpha: 0.5)
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value || old.color != color;
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.accent = Wg.teal,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return WgCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: monoStyle.copyWith(
                  fontSize: 22, fontWeight: FontWeight.w600, color: accent)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.1,
                  color: Wg.textFaint,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Logo bouclier minimal.
class ShieldMark extends StatelessWidget {
  const ShieldMark({super.key, this.size = 34, this.color = Wg.teal});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Wg.cyan],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -4),
        ],
      ),
      child: Icon(Icons.shield_rounded, size: size * 0.55, color: const Color(0xFF04241E)),
    );
  }
}
