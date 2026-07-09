/// Moteur heuristique WariGuard — analyse 100% locale, sur l'appareil.
///
/// Règles pondérées adaptées au contexte ivoirien (français + Nouchi).
/// Produit exactement le même JSON que le futur modèle ML de l'équipe
/// (contrat : docs/CONTRAT_MODELE.md). Quand le modèle sera prêt, il suffira
/// de basculer AppState.engineSource vers l'API sans toucher aux écrans.
library;

import 'dart:math' as math;

import '../models.dart';

class _Rule {
  const _Rule(this.pattern, this.weight, this.label, this.category);

  final String pattern;
  final double weight;
  final String label;
  final String category;
}

const double kRedThreshold = 0.65;
const double kOrangeThreshold = 0.35;

const List<_Rule> _rules = [
  // --- Demande de code secret (signal quasi certain) ---
  _Rule(r"(code|pin|mot de passe|otp)\b.{0,40}\b(envoie|envoyer|donne|donner|communique|confirme|confirmer|tape|taper|transmets?)", 0.55,
      'demande de code secret', 'demande_code'),
  _Rule(r"(envoie|donne|donnez|communique|communiquez|confirme|confirmez|tape|tapez)\b.{0,40}\b(ton|votre|le|vos)?\s*(code|pin|mot de passe|otp)", 0.55,
      'demande de code secret', 'demande_code'),
  _Rule(r"code (secret|de validation|de confirmation|momo|orange money|wave)", 0.5,
      'demande de code secret', 'demande_code'),
  _Rule(r"compose\w*\b.{0,30}[#*]\d", 0.5, 'composition USSD demandée', 'demande_code'),
  _Rule(r"[#*]\d{2,3}[#*]", 0.35, 'syntaxe USSD suspecte', 'demande_code'),
  // --- Faux agent / usurpation d'opérateur ---
  _Rule(r"(agent|conseiller|service client|assistance|technicien|operateur|siege)\b.{0,50}\b(orange|mtn|moov|wave|momo|djamo|mobile money)", 0.45,
      "usurpation d'identité d'agent", 'faux_agent'),
  _Rule(r"(orange|mtn|moov|wave|djamo)\b.{0,30}\b(agent|service|assistance|securite|technique)", 0.4,
      "usurpation d'identité d'opérateur", 'faux_agent'),
  _Rule(r"(ton|votre) (compte|ligne|carte sim|sim|numero)\b.{0,60}\b(bloque|suspendu|desactive|ferme|expire|probleme|pirate|migre)", 0.45,
      'menace de blocage de compte', 'faux_agent'),
  _Rule(r"(verification|mise a jour|reactiv\w+|regularis\w+|kyc)\b.{0,40}\b(compte|sim|carte|numero|identite|obligatoire)", 0.35,
      'prétexte de vérification', 'faux_agent'),
  _Rule(r"(compte|ligne|numero|sim)\b.{0,30}\b(sera|va etre)\b.{0,20}\b(bloque|suspendu|ferme|supprime|desactive)", 0.45,
      'menace de blocage de compte', 'faux_agent'),
  // --- Faux gain ---
  _Rule(r"felicitation|bravo\b|\bgagne\b|gagnant|remporte", 0.35, 'annonce de gain', 'faux_gain'),
  _Rule(r"loterie|tombola|tirage|jackpot|promo(tion)? speciale|jeu concours", 0.4,
      'loterie fictive', 'faux_gain'),
  _Rule(r"(lot|prix|cadeau|bon d.achat|recompense|bonus|gain)\b.{0,40}\b(reclamer|recuperer|retirer|recevoir|valider|debloquer)", 0.45,
      'réclamation de lot', 'faux_gain'),
  _Rule(r"frais (de dossier|de retrait|d.envoi|de livraison|de douane)", 0.5,
      "frais à payer d'avance", 'faux_gain'),
  _Rule(r"(depose|envoie|paye[zr]?)\b.{0,30}\b\d[\d .]*\s*(f|fcfa|francs?)\b.{0,40}\b(recois|recevoir|retour|gagne)", 0.45,
      'promesse de multiplication d\'argent', 'faux_gain'),
  // --- Transfert erroné ---
  _Rule(r"(envoye|transfere|depose|credite|parti[es]?)\b.{0,50}\bpar erreur", 0.55,
      'faux transfert par erreur', 'transfert_errone'),
  _Rule(r"par erreur\b.{0,60}\b(renvoie|renvoyer|renvoyez|rembourse|retourne[zr]?|restitue)", 0.55,
      'demande de remboursement', 'transfert_errone'),
  _Rule(r"(renvoie|renvoyez|rembourse[zr]?|retourne[zr]?)[ -]?(moi|nous)?\b.{0,40}\b(argent|somme|depot|transfert|unites?|\d[\d .]*\s*(f|fcfa|francs?))", 0.4,
      "demande de renvoi d'argent", 'transfert_errone'),
  _Rule(r"je me suis trompe\b.{0,40}\b(numero|destinataire)", 0.5,
      'erreur de numéro simulée', 'transfert_errone'),
  _Rule(r"erreur\b.{0,40}\b(sur (ton|votre) (numero|compte|momo)|technique)", 0.35,
      'prétexte d\'erreur technique', 'transfert_errone'),
  // --- Urgence / pression (amplificateurs) ---
  _Rule(r"urgent|urgence|\bvite\b|rapidement|immediatement|tout de suite|maintenant|dernier delai|dans les \d+ (minutes?|heures?)|avant (ce soir|midi|minuit|18h|20h)", 0.2,
      'pression temporelle', 'urgence'),
  _Rule(r"\bsinon\b|avant qu|expire|sera (bloque|supprime|ferme)|obliges? de|porte plainte|la justice", 0.2,
      'menace conditionnelle', 'urgence'),
  _Rule(r"ne (le )?di(s|tes) a personne|garde (ca|le) secret|confidentiel|ne verifie[zs]? (meme )?pas", 0.3,
      'demande de secret', 'urgence'),
  // --- Nouchi (mise en confiance locale) ---
  _Rule(r"mogo|vieux pere|tchoko|djossi|gaou|c.est gbe|\bgbe\b|faut gerer ca|ya foye|frerot?\b.{0,30}(argent|momo|envoie)|balles pour toi", 0.15,
      'expression Nouchi de mise en confiance', 'nouchi'),
  _Rule(r"\bbara\b|ma go\b|desce?nds? l.argent|fais? vite le truc|c.est chaud", 0.2,
      'pression en Nouchi', 'nouchi'),
  // --- Liens ---
  _Rule(r"https?://\S+|www\.\S+|\b[a-z0-9-]+\.(xyz|top|click|buzz|info|live|icu|cam|rest)\b", 0.25,
      'lien à vérifier', 'lien'),
  _Rule(r"(bit\.ly|tinyurl|cutt\.ly|t\.co|goo\.gl|is\.gd|rb\.gy|shorturl)", 0.35,
      "raccourcisseur d'URL", 'lien'),
  _Rule(r"(clique[zr]?|ouvre[zr]?|suis le lien|via le lien|sur le lien|telecharge[zr]?)", 0.2,
      'incitation au clic', 'lien'),
];

const Map<String, ScamType> _categoryToScam = {
  'demande_code': ScamType.fauxAgent,
  'faux_agent': ScamType.fauxAgent,
  'faux_gain': ScamType.fauxGain,
  'transfert_errone': ScamType.transfertErrone,
  'lien': ScamType.phishingLien,
};

const Map<ScamType, String> _recommendations = {
  ScamType.fauxAgent:
      "Raccrochez / ne répondez pas. Un opérateur ne demande JAMAIS votre code. Appelez vous-même le service client officiel.",
  ScamType.fauxGain:
      "Ignorez ce message. Aucun gain légitime n'exige de frais ou de code pour être « débloqué ».",
  ScamType.transfertErrone:
      "Ne renvoyez rien. Vérifiez votre solde réel dans l'application officielle avant toute action.",
  ScamType.phishingLien: "N'ouvrez pas ce lien. Vérifiez-le d'abord avec Link Shield.",
  ScamType.aucun: "Aucune action requise. Restez vigilant sur les demandes de code ou d'argent.",
};

String _normalize(String text) {
  var t = text.toLowerCase();
  const accents = 'àâäéèêëîïôöùûüçñ';
  const plain = 'aaaeeeeiioouuucn';
  for (var i = 0; i < accents.length; i++) {
    t = t.replaceAll(accents[i], plain[i]);
  }
  return t;
}

class DetectionEngine {
  DetectionEngine()
      : _compiled = [
          for (final r in _rules)
            (RegExp(r.pattern, caseSensitive: false), r),
        ];

  static const String name = 'WariGuard-Local';
  static const String version = '1.0.0';

  final List<(RegExp, _Rule)> _compiled;

  AnalysisResult analyze(String text, MessageChannel channel) {
    final sw = Stopwatch()..start();
    final normalized = _normalize(text);

    final triggers = <Trigger>[];
    final categoryScores = <String, double>{};
    final seenLabels = <String>{};

    for (final (regex, rule) in _compiled) {
      final match = regex.firstMatch(normalized);
      if (match == null) continue;
      categoryScores.update(rule.category, (v) => v + rule.weight,
          ifAbsent: () => rule.weight);
      if (seenLabels.add(rule.label)) {
        final snippet = match.group(0)!.trim();
        triggers.add(Trigger(
          text: snippet.length > 60 ? '${snippet.substring(0, 57)}…' : snippet,
          category: rule.label,
          weight: rule.weight,
        ));
      }
    }

    // Somme plafonnée des signaux « cœur », amplifiée par urgence/Nouchi.
    double base = 0;
    double amplifiers = 0;
    categoryScores.forEach((cat, s) {
      if (cat == 'urgence' || cat == 'nouchi') {
        amplifiers += s;
      } else {
        base += math.min(s, 0.7);
      }
    });
    var score = base + (base > 0 ? amplifiers : amplifiers * 0.5);
    score = score.clamp(0.0, 1.0);

    var scamType = ScamType.aucun;
    final core = {
      for (final e in categoryScores.entries)
        if (_categoryToScam.containsKey(e.key)) e.key: e.value,
    };
    if (core.isNotEmpty && score >= kOrangeThreshold) {
      final dominant =
          core.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      scamType = _categoryToScam[dominant]!;
    }

    final level = score >= kRedThreshold
        ? RiskLevel.rouge
        : score >= kOrangeThreshold
            ? RiskLevel.orange
            : RiskLevel.vert;

    triggers.sort((a, b) => b.weight.compareTo(a.weight));
    sw.stop();

    return AnalysisResult(
      riskScore: double.parse(score.toStringAsFixed(3)),
      riskLevel: level,
      scamType: scamType,
      triggers: triggers.take(8).toList(),
      explanation: _explain(level, scamType, triggers, channel),
      recommendation: _recommendations[scamType]!,
      modelName: name,
      modelVersion: version,
      latencyMs: sw.elapsedMicroseconds / 1000,
    );
  }

  static String _explain(RiskLevel level, ScamType scamType,
      List<Trigger> triggers, MessageChannel channel) {
    final source = channel == MessageChannel.sms ? 'Ce SMS' : 'Cet appel';
    if (level == RiskLevel.vert) {
      return "$source ne présente aucun signal d'arnaque connu.";
    }
    final labels =
        triggers.take(4).map((t) => t.category).toSet().join(', ');
    const typeLabels = {
      ScamType.fauxAgent: "une usurpation d'identité d'agent Mobile Money",
      ScamType.fauxGain: 'une arnaque au faux gain',
      ScamType.transfertErrone: 'une arnaque au faux transfert erroné',
      ScamType.phishingLien: 'une tentative de phishing par lien',
      ScamType.aucun: 'un contenu suspect',
    };
    final certainty =
        level == RiskLevel.rouge ? 'correspond fortement à' : 'présente des signes de';
    return '$source $certainty ${typeLabels[scamType]}. Signaux détectés : $labels.';
  }
}
