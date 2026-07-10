/// Onboarding en deux étapes, fidèle au prototype :
///   1. Écran d'accueil — bouclier vert, « Le bouclier intelligent contre le
///      phishing vocal », bouton Continuer.
///   2. Consentement — pastille cadenas, choix du mode d'activation
///      (exigence MVP : ≥ 2 modes) + boucliers actifs.
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
  late bool _showWelcome;
  late ConsentMode _mode;
  late bool _textShield;
  late bool _linkShield;
  late bool _behaviorShield;

  @override
  void initState() {
    super.initState();
    _showWelcome = !widget.editMode;
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
    return Scaffold(
      backgroundColor: Wg.bg,
      body: SafeArea(
        child: _showWelcome ? _buildWelcome(context) : _buildConsent(context),
      ),
    );
  }

  // ---- Étape 1 : écran d'accueil du prototype ----

  Widget _buildWelcome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        children: [
          const Spacer(flex: 3),
          const ShieldMark(size: 110),
          const SizedBox(height: 40),
          const Text('WARIGUARD',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: Wg.green)),
          const SizedBox(height: 14),
          Text(
            'Le bouclier intelligent\ncontre le phishing vocal',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 27),
          ),
          const SizedBox(height: 14),
          const Text(
            'WariGuard détecte les arnaques Mobile\nMoney en temps réel et vous protège\navant qu\'il ne soit trop tard.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Wg.textDim, height: 1.55, fontSize: 15),
          ),
          const Spacer(flex: 4),
          ElevatedButton(
            onPressed: () => setState(() => _showWelcome = false),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continuer'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Étape 2 : consentement (layout « autorisations » du prototype) ----

  Widget _buildConsent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        Row(
          children: [
            const IconBubble(icon: Icons.lock_rounded),
            const Spacer(),
            if (widget.editMode)
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Wg.textDim),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.editMode
              ? 'Votre consentement,\nvos règles'
              : 'Votre protection,\nvos règles',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 10),
        const Text(
          "WariGuard n'analyse que ce que vous autorisez. Tout se passe sur "
          "votre téléphone : rien n'est enregistré ni envoyé.",
          style: TextStyle(color: Wg.textDim, height: 1.55, fontSize: 14.5),
        ),
        const SizedBox(height: 24),
        const SectionLabel("Mode d'activation"),
        _ModeCard(
          mode: ConsentMode.permanent,
          selected: _mode == ConsentMode.permanent,
          icon: Icons.verified_user_rounded,
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
        const SizedBox(height: 24),
        const SectionLabel('Boucliers actifs'),
        WgCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _ShieldSwitch(
                title: 'Text Shield',
                subtitle: 'SMS et transcriptions d\'appel',
                icon: Icons.sms_rounded,
                value: _textShield,
                onChanged: (v) => setState(() => _textShield = v),
              ),
              const Divider(height: 1),
              _ShieldSwitch(
                title: 'Link Shield',
                subtitle: 'Liens vérifiés avant ouverture',
                icon: Icons.link_rounded,
                value: _linkShield,
                onChanged: (v) => setState(() => _linkShield = v),
              ),
              const Divider(height: 1),
              _ShieldSwitch(
                title: 'Behavior Shield',
                subtitle: 'Détection comportementale — bientôt disponible',
                icon: Icons.insights_rounded,
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
          child: Text(
              widget.editMode ? 'Enregistrer mes choix' : 'Autoriser et continuer'),
        ),
        const SizedBox(height: 10),
        if (!widget.editMode)
          TextButton(
            onPressed: () {
              setState(() => _mode = ConsentMode.desactive);
              _confirm();
            },
            child: const Text('Plus tard'),
          ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 13, color: Wg.textFaint),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Analyse locale · données chiffrées AES-256 · révocable à tout moment',
                style: TextStyle(color: Wg.textFaint, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ],
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
      borderColor: selected ? Wg.green : Wg.border,
      color: selected ? Wg.greenTint : Wg.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Wg.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: selected ? Wg.green : Wg.textDim),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Wg.text)),
                const SizedBox(height: 3),
                Text(mode.description,
                    style: const TextStyle(
                        fontSize: 12, color: Wg.textDim, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: selected ? Wg.green : Wg.textFaint,
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
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value && enabled,
      onChanged: enabled ? onChanged : null,
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Wg.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 19, color: enabled ? Wg.text : Wg.textFaint),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: enabled ? Wg.text : Wg.textFaint)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Wg.textFaint)),
    );
  }
}
