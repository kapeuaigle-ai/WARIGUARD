/// Composants partagés — reprise du design system du prototype :
/// cartes bordées, toggle à libellé, étiquette de section, chip bouclier.
library;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Carte blanche bordée (rayon 18), brique de base du prototype.
class WgCard extends StatelessWidget {
  const WgCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.color,
    this.radius = 18,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Wg.bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Wg.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

/// Étiquette de section en capitales (PROTECTION, AUTORISATIONS…).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: Wg.textFaint,
          ),
        ),
      );
}

/// Interrupteur du prototype (piste 52×31, pastille 25) + libellé texte.
class WgToggle extends StatelessWidget {
  const WgToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: _buildSwitch(),
    );
  }

  Widget _buildSwitch() {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 31,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? Wg.green : Wg.trackOff,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne « libellé + sous-texte + toggle » (Paramètres, carte d'état).
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          Icon(leading, size: 22, color: Wg.text),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12.5, color: Wg.textDim)),
              ],
            ],
          ),
        ),
        WgToggle(value: value, onChanged: onChanged, semanticLabel: title),
      ],
    );
  }
}

/// Chip du bouclier ayant détecté la menace — « Bouclier Texte » / « Lien ».
class ShieldChip extends StatelessWidget {
  const ShieldChip(this.shield, {super.key, this.tone = Wg.green});

  final Shield shield;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(shield.icon, size: 15, color: tone),
          const SizedBox(width: 6),
          Text(shield.label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: tone)),
        ],
      ),
    );
  }
}

/// Badge de statut d'alerte (Bloqué / Signalé / Ignoré).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final AlertStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      AlertStatus.blocked => (Wg.greenTint, Wg.greenBadge),
      AlertStatus.reported => (Wg.orangeTint, Wg.orangeDeep),
      AlertStatus.ignored => (Wg.borderSoft, Wg.textDim),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(status.label,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

/// Pastille de risque « RISQUE ÉLEVÉ / MOYEN ».
class RiskPill extends StatelessWidget {
  const RiskPill(this.level, {super.key});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final color = Wg.riskColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              level == RiskLevel.vert
                  ? Icons.check_rounded
                  : Icons.priority_high_rounded,
              size: 14,
              color: Colors.white),
          const SizedBox(width: 4),
          Text('RISQUE ${Wg.riskWord(level)}',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

/// Petit logo bouclier (carré arrondi vert, icône blanche).
class ShieldMark extends StatelessWidget {
  const ShieldMark({super.key, this.size = 28, this.color = Wg.green});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: Icon(Icons.verified_user_rounded,
          size: size * 0.6, color: Colors.white),
    );
  }
}

/// Pastille d'icône teintée (permissions, en-têtes).
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    this.color = Wg.green,
    this.bg = Wg.greenTint,
    this.size = 52,
    this.radius = 15,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}
