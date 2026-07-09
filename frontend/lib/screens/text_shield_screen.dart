/// Text Shield — simulateur SMS / appel entrant + analyse + alerte visuelle
/// rouge / orange / vert. Cœur de la démo live du pitch.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../services/link_shield.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'link_shield_screen.dart' show LinkVerdictSheet;

class TextShieldScreen extends StatefulWidget {
  const TextShieldScreen({super.key});

  @override
  State<TextShieldScreen> createState() => _TextShieldScreenState();
}

class _TextShieldScreenState extends State<TextShieldScreen> {
  final _controller = TextEditingController();
  MessageChannel _channel = MessageChannel.sms;

  String? _incomingText;
  bool _analyzing = false;
  AnalysisResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(String text) async {
    final state = context.read<AppState>();
    if (!state.protectionActive || !state.consent.textShield) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Text Shield est désactivé — activez-le dans Sécurité.'),
      ));
      return;
    }
    setState(() {
      _incomingText = text;
      _analyzing = true;
      _result = null;
    });
    // Petite latence scénarisée : laisse le jury voir le message arriver.
    await Future.delayed(const Duration(milliseconds: 650));
    final result = await state.analyzeText(text, _channel);
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      _result = result;
    });
  }

  void _reset() => setState(() {
        _incomingText = null;
        _result = null;
        _analyzing = false;
        _controller.clear();
      });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scenarios = state.ready ? state.dataset.demoScenarios() : <DatasetExample>[];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Row(
              children: [
                Text('Text Shield', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                if (_incomingText != null)
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Wg.textDim),
                    label: const Text('Réinitialiser',
                        style: TextStyle(color: Wg.textDim, fontSize: 12)),
                  ),
              ],
            ),
            const Text(
              'Simulez un SMS ou un appel entrant. WariGuard analyse et alerte en direct.',
              style: TextStyle(color: Wg.textDim, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // ---- Canal ----
            Row(
              children: [
                _ChannelChip(
                  label: 'SMS',
                  icon: Icons.sms_rounded,
                  selected: _channel == MessageChannel.sms,
                  onTap: () => setState(() => _channel = MessageChannel.sms),
                ),
                const SizedBox(width: 8),
                _ChannelChip(
                  label: 'Appel (transcription)',
                  icon: Icons.phone_rounded,
                  selected: _channel == MessageChannel.appel,
                  onTap: () => setState(() => _channel = MessageChannel.appel),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Scénarios prêts ----
            const SectionLabel('Scénarios de démonstration'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in scenarios)
                  ActionChip(
                    onPressed: () {
                      setState(() => _channel = s.channel);
                      _run(s.text);
                    },
                    backgroundColor: Wg.surface,
                    side: const BorderSide(color: Wg.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    avatar: Icon(
                      s.label == ScamType.aucun
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      size: 15,
                      color: s.label == ScamType.aucun ? Wg.green : Wg.orange,
                    ),
                    label: Text(
                      s.label == ScamType.aucun ? 'Message légitime' : s.label.label,
                      style: const TextStyle(fontSize: 12, color: Wg.text),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Saisie libre ----
            TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: _channel == MessageChannel.sms
                    ? 'Collez ou tapez un SMS suspect…'
                    : 'Collez la transcription d\'un appel…',
                suffixIcon: IconButton(
                  onPressed: () {
                    final t = _controller.text.trim();
                    if (t.isNotEmpty) _run(t);
                  },
                  icon: const Icon(Icons.shield_rounded, color: Wg.teal),
                  tooltip: 'Analyser',
                ),
              ),
              onSubmitted: (t) {
                if (t.trim().isNotEmpty) _run(t.trim());
              },
            ),
            const SizedBox(height: 20),

            // ---- Message entrant simulé ----
            if (_incomingText != null) ...[
              SectionLabel(_channel == MessageChannel.sms
                  ? 'SMS entrant'
                  : 'Appel entrant — transcription live'),
              _IncomingBubble(
                text: _incomingText!,
                channel: _channel,
                result: _result,
              ),
              const SizedBox(height: 14),
            ],

            // ---- Analyse en cours ----
            if (_analyzing) const _AnalyzingCard(),

            // ---- Verdict ----
            if (_result != null) _VerdictCard(result: _result!, sourceText: _incomingText!),
          ],
        ),
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Wg.teal.withValues(alpha: 0.12) : Wg.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Wg.teal : Wg.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? Wg.teal : Wg.textDim),
              const SizedBox(width: 7),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? Wg.teal : Wg.textDim)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingBubble extends StatelessWidget {
  const _IncomingBubble({required this.text, required this.channel, this.result});

  final String text;
  final MessageChannel channel;
  final AnalysisResult? result;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        result == null ? Wg.border : Wg.riskColor(result!.riskLevel).withValues(alpha: 0.55);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Wg.surfaceHi,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: Wg.bgDeep,
                  child: Icon(
                    channel == MessageChannel.sms
                        ? Icons.person_rounded
                        : Icons.phone_in_talk_rounded,
                    size: 13,
                    color: Wg.textDim,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Numéro inconnu · +225 XX XX XX XX',
                    style: monoStyle.copyWith(fontSize: 10.5, color: Wg.textFaint)),
              ],
            ),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(fontSize: 13.5, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingCard extends StatelessWidget {
  const _AnalyzingCard();

  @override
  Widget build(BuildContext context) {
    return WgCard(
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Wg.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Analyse WariGuard en cours…',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text('Moteur local · aucune donnée ne quitte l\'appareil',
                    style: monoStyle.copyWith(fontSize: 10.5, color: Wg.textFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.result, required this.sourceText});

  final AnalysisResult result;
  final String sourceText;

  @override
  Widget build(BuildContext context) {
    final color = Wg.riskColor(result.riskLevel);
    final urls = LinkShield.extractUrls(sourceText);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: WgCard(
        borderColor: color.withValues(alpha: 0.5),
        color: Color.alphaBlend(color.withValues(alpha: 0.05), Wg.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RiskBadge(result.riskLevel),
                const Spacer(),
                if (result.scamType != ScamType.aucun)
                  Text(result.scamType.label.toUpperCase(),
                      style: monoStyle.copyWith(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 6),
            Center(child: RiskGauge(score: result.riskScore, level: result.riskLevel)),
            const SizedBox(height: 12),
            Text(result.explanation, style: const TextStyle(fontSize: 13.5, height: 1.5)),
            if (result.triggers.isNotEmpty) ...[
              const SizedBox(height: 14),
              const SectionLabel('Signaux déclencheurs'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in result.triggers.take(6))
                    Tooltip(
                      message: t.category,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text('« ${t.text} »',
                            style: monoStyle.copyWith(fontSize: 10.5, color: Wg.text)),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Wg.bgDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    result.riskLevel == RiskLevel.vert
                        ? Icons.check_circle_rounded
                        : Icons.tips_and_updates_rounded,
                    size: 17,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(result.recommendation,
                        style: const TextStyle(fontSize: 12.5, height: 1.45)),
                  ),
                ],
              ),
            ),
            if (urls.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => LinkVerdictSheet.show(context, urls.first),
                icon: const Icon(Icons.link_rounded, size: 17),
                label: Text('Vérifier le lien avec Link Shield (${urls.length})'),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${result.modelName} v${result.modelVersion} · ${result.latencyMs.toStringAsFixed(1)} ms · score ${result.riskScore.toStringAsFixed(2)}',
              style: monoStyle.copyWith(fontSize: 9.5, color: Wg.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}
