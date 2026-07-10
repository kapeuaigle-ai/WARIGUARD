/// Onboarding 1 — Bienvenue. Un seul CTA, pas de distraction (cahier des
/// charges §3.0). Bouclier vert avec halo pulsant.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 34),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _PulsingShield(),
                const SizedBox(height: 40),
                const Text('WARIGUARD',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.7,
                        color: Wg.green)),
                const SizedBox(height: 16),
                Text('Le bouclier intelligent contre le phishing vocal',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 27)),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 280,
                  child: Text(
                    "WariGuard détecte les arnaques Mobile Money en temps réel et vous "
                    "protège avant qu'il ne soit trop tard.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.55, color: Wg.textDim),
                  ),
                ),
              ],
            ),
          ),
          _GreenButton(
            label: 'Continuer',
            trailing: Icons.arrow_forward_rounded,
            onTap: onContinue,
          ),
        ],
      ),
    );
  }
}

class _PulsingShield extends StatefulWidget {
  const _PulsingShield();

  @override
  State<_PulsingShield> createState() => _PulsingShieldState();
}

class _PulsingShieldState extends State<_PulsingShield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _c.value;
              final scale = 1 + 0.12 * (v < 0.5 ? v * 2 : (1 - v) * 2);
              final opacity = 0.5 * (1 - v);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: Wg.greenTint.withValues(alpha: opacity.clamp(0, 0.5)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: Wg.green,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(Icons.verified_user_rounded, size: 56, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _GreenButton extends StatelessWidget {
  const _GreenButton({required this.label, required this.onTap, this.trailing});

  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Wg.green,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, size: 20, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
