/// Écran de consentement — exigence MVP : au moins deux modes d'activation,
/// contrôle utilisateur explicite avant toute analyse.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.editMode = false});

  /// true quand ouvert depuis l'écran Sécurité pour modifier le consentement.
  final bool editMode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late ConsentMode _mode;
  late bool _textShield;
  late bool _linkShield;
  late bool _behaviorShield;

  @override
  void initState() {
    super.initState();
    final consent = context.read<AppState>().consent;
    _mode = widget.editMode ? consent.mode : ConsentMode.aLaDemande;
    _textShield = consent.textShield;
    _linkShield = consent.linkShield;
    _behaviorShield = consent.behaviorShield;
  }

  Future<void> _confirm() async {
    final state = context.read<AppState>();
    await state.updateConsent(ConsentSettings(
      mode: _mode,
      textShield: _textShield,
      linkShield: _linkShield,
      behaviorShield: _behaviorShield,
      onboarded: true,
    ));
    if (widget.editMode && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.9),
            radius: 1.6,
            colors: [Color(0xFF0B2C42), Wg.bg],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            children: [
              Row(
                children: [
                  const ShieldMark(size: 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WariGuard', style: theme.textTheme.titleLarge),
                      const Text('par ClaPay SA',
                          style: TextStyle(color: Wg.textFaint, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  if (widget.editMode)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Wg.textDim),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                widget.editMode
                    ? 'Votre consentement,\nvos règles.'
                    : 'Votre argent mérite\nun garde du corps.',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 10),
              const Text(
                "WariGuard analyse les SMS, appels et liens pour bloquer les arnaques "
                "Mobile Money. Tout se passe sur votre téléphone : rien n'est envoyé "
                "sans votre accord. Choisissez comment le bouclier s'active.",
                style: TextStyle(color: Wg.textDim, height: 1.55),
              ),
              const SizedBox(height: 26),
              const SectionLabel("Mode d'activation"),
              _ModeCard(
                mode: ConsentMode.permanent,
                selected: _mode == ConsentMode.permanent,
                icon: Icons.shield_rounded,
                onTap: () => setState(() => _mode = ConsentMode.permanent),
              ),
              const SizedBox(height: 10),
              _ModeCard(
                mode: ConsentMode.aLaDemande,
                selected: _mode == ConsentMode.aLaDemande,
                icon: Icons.touch_app_rounded,
                onTap: () => setState(() => _mode = ConsentMode.aLaDemande),
              ),
              const SizedBox(height: 10),
              _ModeCard(
                mode: ConsentMode.desactive,
                selected: _mode == ConsentMode.desactive,
                icon: Icons.shield_outlined,
                onTap: () => setState(() => _mode = ConsentMode.desactive),
              ),
              const SizedBox(height: 26),
              const SectionLabel('Boucliers actifs'),
              WgCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    _ShieldSwitch(
                      title: 'Text Shield',
                      subtitle: 'SMS et transcriptions d\'appel',
                      value: _textShield,
                      onChanged: (v) => setState(() => _textShield = v),
                    ),
                    const Divider(height: 1),
                    _ShieldSwitch(
                      title: 'Link Shield',
                      subtitle: 'Liens vérifiés avant ouverture',
                      value: _linkShield,
                      onChanged: (v) => setState(() => _linkShield = v),
                    ),
                    const Divider(height: 1),
                    _ShieldSwitch(
                      title: 'Behavior Shield',
                      subtitle: 'Détection comportementale — bientôt disponible',
                      value: _behaviorShield,
                      enabled: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _confirm,
                child: Text(widget.editMode
                    ? 'Enregistrer mes choix'
                    : 'Activer WariGuard'),
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 13, color: Wg.textFaint),
                  SizedBox(width: 6),
                  Text('Analyse locale · données chiffrées AES-256 · révocable à tout moment',
                      style: TextStyle(color: Wg.textFaint, fontSize: 10.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final ConsentMode mode;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WgCard(
      onTap: onTap,
      borderColor: selected ? Wg.teal : Wg.border,
      color: selected ? Wg.teal.withValues(alpha: 0.07) : Wg.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? Wg.teal.withValues(alpha: 0.15) : Wg.bgDeep,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: selected ? Wg.teal : Wg.textDim),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? Wg.text : Wg.textDim)),
                const SizedBox(height: 3),
                Text(mode.description,
                    style: const TextStyle(fontSize: 12, color: Wg.textFaint, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: selected ? Wg.teal : Wg.textFaint,
          ),
        ],
      ),
    );
  }
}

class _ShieldSwitch extends StatelessWidget {
  const _ShieldSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value && enabled,
      onChanged: enabled ? onChanged : null,
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: enabled ? Wg.text : Wg.textFaint)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Wg.textFaint)),
    );
  }
}
