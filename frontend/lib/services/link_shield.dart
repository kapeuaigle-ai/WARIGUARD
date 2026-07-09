/// Link Shield — vérification heuristique d'URL avant ouverture, en local.
library;

import '../models.dart';

const _shorteners = {
  'bit.ly', 'tinyurl.com', 'cutt.ly', 't.co', 'goo.gl', 'is.gd',
  'rb.gy', 'shorturl.at', 'rebrand.ly', 's.id', 'tny.im',
};

const _officialDomains = {
  'orange.ci', 'orange.com', 'mtn.ci', 'mtn.com', 'moov-africa.ci',
  'wave.com', 'djamo.com', 'gouv.ci',
};

const _brands = ['orange', 'mtn', 'moov', 'wave', 'momo', 'djamo'];

const _riskyTlds = ['.xyz', '.top', '.click', '.buzz', '.info', '.live', '.icu', '.cam', '.rest'];

const _baitWords = [
  'gagner', 'gain', 'cadeau', 'promo', 'bonus', 'reclamer', 'recompense',
  'gratuit', 'verification', 'verifier', 'compte', 'securite', 'deblocage',
  'urgent', 'prize', 'win', 'claim', 'free', 'reward', 'update',
];

String _registeredDomain(String host) {
  final parts = host.split('.');
  if (parts.length >= 3 &&
      const {'co', 'com', 'gouv', 'org', 'net'}.contains(parts[parts.length - 2]) &&
      parts.last.length == 2) {
    return parts.sublist(parts.length - 3).join('.');
  }
  return parts.length >= 2 ? parts.sublist(parts.length - 2).join('.') : host;
}

class LinkShield {
  static LinkCheckResult check(String rawUrl) {
    var url = rawUrl.trim();
    if (!RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(url)) {
      url = 'http://$url';
    }

    final uri = Uri.tryParse(url);
    final host = (uri?.host ?? '').toLowerCase();
    final domain = _registeredDomain(host);
    final pathQuery = '${uri?.path ?? ''}?${uri?.query ?? ''}'.toLowerCase();

    final reasons = <String>[];
    double score = 0;

    if (_officialDomains.contains(domain)) {
      return LinkCheckResult(
        url: rawUrl,
        domain: domain,
        verdict: LinkVerdict.sur,
        riskScore: 0.02,
        reasons: const ['Domaine officiel reconnu'],
      );
    }

    if (_shorteners.contains(domain)) {
      score += 0.45;
      reasons.add("Raccourcisseur d'URL ($domain) : la destination réelle est masquée");
    }

    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) {
      score += 0.5;
      reasons.add("Adresse IP brute au lieu d'un nom de domaine");
    }

    for (final brand in _brands) {
      if (host.contains(brand)) {
        score += 0.5;
        reasons.add(
            'Usurpation probable de la marque « $brand » (domaine non officiel : $domain)');
        break;
      }
    }

    for (final tld in _riskyTlds) {
      if (host.endsWith(tld)) {
        score += 0.3;
        reasons.add('Extension de domaine à risque ($tld)');
        break;
      }
    }

    final baits = _baitWords
        .where((w) => host.contains(w) || pathQuery.contains(w))
        .toSet()
        .toList()
      ..sort();
    if (baits.isNotEmpty) {
      score += (0.15 * baits.length).clamp(0.0, 0.4);
      reasons.add("Mots d'appât dans le lien : ${baits.take(4).join(', ')}");
    }

    if (uri?.scheme == 'http') {
      score += 0.15;
      reasons.add('Connexion non sécurisée (pas de HTTPS)');
    }

    if ('-'.allMatches(host).length >= 2) {
      score += 0.15;
      reasons.add('Domaine composite suspect (tirets multiples)');
    }

    if (host.split('.').length >= 4) {
      score += 0.2;
      reasons.add('Sous-domaines en cascade pour imiter un site légitime');
    }

    score = score.clamp(0.0, 1.0);
    final verdict = score >= 0.6
        ? LinkVerdict.bloque
        : score >= 0.3
            ? LinkVerdict.suspect
            : LinkVerdict.sur;

    if (verdict == LinkVerdict.sur && reasons.isEmpty) {
      reasons.add('Aucun signal malveillant détecté');
    }

    return LinkCheckResult(
      url: rawUrl,
      domain: domain.isEmpty ? 'inconnu' : domain,
      verdict: verdict,
      riskScore: double.parse(score.toStringAsFixed(3)),
      reasons: reasons,
    );
  }

  /// Extrait les URLs d'un texte (pour blocage avant ouverture dans Text Shield).
  static List<String> extractUrls(String text) {
    final re = RegExp(
        r"(https?://[^\s]+|www\.[^\s]+|\b[a-z0-9-]+\.(ly|co|gl|gd|gy|at|id|im|com|ci|xyz|top|click|buzz|info|live|icu|cam|rest)/[^\s]*)",
        caseSensitive: false);
    return re.allMatches(text).map((m) => m.group(0)!).toList();
  }
}
