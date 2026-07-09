/// Link Shield — vérification d'URL + interstitiel de blocage avant ouverture.
/// Exigence MVP : « un lien malveillant détecté et bloqué avant ouverture ».
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LinkShieldScreen extends StatefulWidget {
  const LinkShieldScreen({super.key});

  @override
  State<LinkShieldScreen> createState() => _LinkShieldScreenState();
}

class _LinkShieldScreenState extends State<LinkShieldScreen> {
  final _controller = TextEditingController();
  LinkCheckResult? _result;

  static const _demoLinks = [
    ('http://orange-money-verification.xyz/compte', 'Faux site opérateur'),
    ('bit.ly/mtn-gain', 'Lien raccourci suspect'),
    ('http://185.22.14.8/mtn-update.apk', 'APK sur adresse IP'),
    ('https://wave.com', 'Site officiel Wave'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check(String url) {
    final state = context.read<AppState>();
    if (!state.protectionActive || !state.consent.linkShield) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Link Shield est désactivé — activez-le dans Sécurité.'),
      ));
      return;
    }
    setState(() => _result = state.checkLink(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text('Link Shield', style: Theme.of(context).textTheme.titleLarge),
            const Text(
              'Chaque lien est inspecté avant ouverture : raccourcisseurs, domaines usurpés, appâts.',
              style: TextStyle(color: Wg.textDim, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              style: monoStyle.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://exemple-suspect.xyz/gain',
                prefixIcon: const Icon(Icons.link_rounded, color: Wg.textFaint, size: 20),
                suffixIcon: IconButton(
                  onPressed: () {
                    final t = _controller.text.trim();
                    if (t.isNotEmpty) _check(t);
                  },
                  icon: const Icon(Icons.search_rounded, color: Wg.teal),
                ),
              ),
              onSubmitted: (t) {
                if (t.trim().isNotEmpty) _check(t.trim());
              },
            ),
            const SizedBox(height: 16),
            const SectionLabel('Liens de démonstration'),
            for (final (url, label) in _demoLinks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WgCard(
                  onTap: () {
                    _controller.text = url;
                    _check(url);
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded, size: 17, color: Wg.textFaint),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: monoStyle.copyWith(fontSize: 11.5)),
                            Text(label,
                                style:
                                    const TextStyle(fontSize: 10.5, color: Wg.textFaint)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Wg.textFaint),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (_result != null) _LinkResultCard(result: _result!),
          ],
        ),
      ),
    );
  }
}

class _LinkResultCard extends StatelessWidget {
  const _LinkResultCard({required this.result});

  final LinkCheckResult result;

  (Color, IconData, String) get _style => switch (result.verdict) {
        LinkVerdict.bloque => (Wg.red, Icons.gpp_bad_rounded, 'LIEN BLOQUÉ'),
        LinkVerdict.suspect => (Wg.orange, Icons.gpp_maybe_rounded, 'LIEN SUSPECT'),
        LinkVerdict.sur => (Wg.green, Icons.gpp_good_rounded, 'LIEN SÛR'),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon, title) = _style;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
      child: WgCard(
        borderColor: color.withValues(alpha: 0.5),
        color: Color.alphaBlend(color.withValues(alpha: 0.05), Wg.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              fontSize: 15)),
                      Text('Domaine : ${result.domain}',
                          style: monoStyle.copyWith(fontSize: 11, color: Wg.textDim)),
                    ],
                  ),
                ),
                Text('${(result.riskScore * 100).round()}',
                    style: monoStyle.copyWith(
                        fontSize: 26, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
            const SizedBox(height: 14),
            for (final reason in result.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                        result.verdict == LinkVerdict.sur
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 14,
                        color: color),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(reason,
                            style: const TextStyle(fontSize: 12.5, height: 1.4))),
                  ],
                ),
              ),
            if (result.verdict == LinkVerdict.bloque) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Wg.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Wg.red.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  "⛔ L'ouverture de ce lien a été bloquée par WariGuard avant tout chargement.",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Feuille modale de verdict — appelée depuis Text Shield quand un message
/// contient un lien (flux « bloqué avant ouverture »).
class LinkVerdictSheet {
  static Future<void> show(BuildContext context, String url) {
    final result = context.read<AppState>().checkLink(url);
    return showModalBottomSheet(
      context: context,
      backgroundColor: Wg.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Wg.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: monoStyle.copyWith(fontSize: 12, color: Wg.textDim)),
            const SizedBox(height: 12),
            _LinkResultCard(result: result),
          ],
        ),
      ),
    );
  }
}
