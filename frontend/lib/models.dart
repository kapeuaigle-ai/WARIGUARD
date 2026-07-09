/// Modèles WariGuard — miroir Dart du contrat JSON partagé avec le futur
/// modèle ML (voir docs/CONTRAT_MODELE.md et backend/app/schemas.py).
library;

enum RiskLevel {
  rouge,
  orange,
  vert;

  static RiskLevel fromJson(String v) => RiskLevel.values.byName(v);
}

enum ScamType {
  fauxAgent('faux_agent', 'Faux agent'),
  fauxGain('faux_gain', 'Faux gain'),
  transfertErrone('transfert_errone', 'Transfert erroné'),
  phishingLien('phishing_lien', 'Phishing par lien'),
  aucun('aucun', 'Aucune menace');

  const ScamType(this.json, this.label);
  final String json;
  final String label;

  static ScamType fromJson(String v) =>
      ScamType.values.firstWhere((e) => e.json == v, orElse: () => ScamType.aucun);
}

enum MessageChannel { sms, appel }

class Trigger {
  const Trigger({required this.text, required this.category, required this.weight});

  final String text;
  final String category;
  final double weight;

  factory Trigger.fromJson(Map<String, dynamic> j) => Trigger(
        text: j['text'] as String,
        category: j['category'] as String,
        weight: (j['weight'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'text': text, 'category': category, 'weight': weight};
}

class AnalysisResult {
  const AnalysisResult({
    required this.riskScore,
    required this.riskLevel,
    required this.scamType,
    required this.triggers,
    required this.explanation,
    required this.recommendation,
    required this.modelName,
    required this.modelVersion,
    required this.latencyMs,
  });

  final double riskScore;
  final RiskLevel riskLevel;
  final ScamType scamType;
  final List<Trigger> triggers;
  final String explanation;
  final String recommendation;
  final String modelName;
  final String modelVersion;
  final double latencyMs;

  factory AnalysisResult.fromJson(Map<String, dynamic> j) => AnalysisResult(
        riskScore: (j['risk_score'] as num).toDouble(),
        riskLevel: RiskLevel.fromJson(j['risk_level'] as String),
        scamType: ScamType.fromJson(j['scam_type'] as String),
        triggers: (j['triggers'] as List)
            .map((t) => Trigger.fromJson(t as Map<String, dynamic>))
            .toList(),
        explanation: j['explanation'] as String,
        recommendation: j['recommendation'] as String,
        modelName: j['model_name'] as String,
        modelVersion: j['model_version'] as String,
        latencyMs: (j['latency_ms'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'risk_score': riskScore,
        'risk_level': riskLevel.name,
        'scam_type': scamType.json,
        'triggers': triggers.map((t) => t.toJson()).toList(),
        'explanation': explanation,
        'recommendation': recommendation,
        'model_name': modelName,
        'model_version': modelVersion,
        'latency_ms': latencyMs,
      };
}

enum LinkVerdict {
  bloque('Bloqué'),
  suspect('Suspect'),
  sur('Sûr');

  const LinkVerdict(this.label);
  final String label;
}

class LinkCheckResult {
  const LinkCheckResult({
    required this.url,
    required this.domain,
    required this.verdict,
    required this.riskScore,
    required this.reasons,
  });

  final String url;
  final String domain;
  final LinkVerdict verdict;
  final double riskScore;
  final List<String> reasons;
}

enum ConsentMode {
  permanent('Protection permanente',
      'WariGuard analyse automatiquement chaque SMS et appel entrant, en arrière-plan.'),
  aLaDemande('À la demande',
      'Rien n\'est analysé sans votre geste : vous soumettez un message quand vous avez un doute.'),
  desactive('Désactivé', 'Aucune analyse. Les boucliers sont éteints.');

  const ConsentMode(this.label, this.description);
  final String label;
  final String description;
}

class ConsentSettings {
  const ConsentSettings({
    this.mode = ConsentMode.aLaDemande,
    this.textShield = true,
    this.linkShield = true,
    this.behaviorShield = false,
    this.onboarded = false,
  });

  final ConsentMode mode;
  final bool textShield;
  final bool linkShield;
  final bool behaviorShield;
  final bool onboarded;

  ConsentSettings copyWith({
    ConsentMode? mode,
    bool? textShield,
    bool? linkShield,
    bool? behaviorShield,
    bool? onboarded,
  }) =>
      ConsentSettings(
        mode: mode ?? this.mode,
        textShield: textShield ?? this.textShield,
        linkShield: linkShield ?? this.linkShield,
        behaviorShield: behaviorShield ?? this.behaviorShield,
        onboarded: onboarded ?? this.onboarded,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'text_shield': textShield,
        'link_shield': linkShield,
        'behavior_shield': behaviorShield,
        'onboarded': onboarded,
      };

  factory ConsentSettings.fromJson(Map<String, dynamic> j) => ConsentSettings(
        mode: ConsentMode.values.byName(j['mode'] as String? ?? 'aLaDemande'),
        textShield: j['text_shield'] as bool? ?? true,
        linkShield: j['link_shield'] as bool? ?? true,
        behaviorShield: j['behavior_shield'] as bool? ?? false,
        onboarded: j['onboarded'] as bool? ?? false,
      );
}

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.channel,
    required this.textPreview,
    required this.riskLevel,
    required this.scamType,
    required this.riskScore,
  });

  final String id;
  final DateTime timestamp;
  final MessageChannel channel;
  final String textPreview;
  final RiskLevel riskLevel;
  final ScamType scamType;
  final double riskScore;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'channel': channel.name,
        'text_preview': textPreview,
        'risk_level': riskLevel.name,
        'scam_type': scamType.json,
        'risk_score': riskScore,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        channel: MessageChannel.values.byName(j['channel'] as String),
        textPreview: j['text_preview'] as String,
        riskLevel: RiskLevel.fromJson(j['risk_level'] as String),
        scamType: ScamType.fromJson(j['scam_type'] as String),
        riskScore: (j['risk_score'] as num).toDouble(),
      );
}

/// Exemple annoté du jeu de données embarqué.
class DatasetExample {
  const DatasetExample({
    required this.id,
    required this.channel,
    required this.label,
    required this.text,
  });

  final int id;
  final MessageChannel channel;
  final ScamType label; // aucun == legitime
  final String text;

  bool get isScam => label != ScamType.aucun;

  factory DatasetExample.fromJson(Map<String, dynamic> j) => DatasetExample(
        id: j['id'] as int,
        channel: MessageChannel.values.byName(j['channel'] as String),
        label: j['label'] == 'legitime'
            ? ScamType.aucun
            : ScamType.fromJson(j['label'] as String),
        text: j['text'] as String,
      );
}

/// Métriques réelles calculées en exécutant le moteur sur le dataset embarqué.
class ModelMetrics {
  const ModelMetrics({
    required this.totalExamples,
    required this.scamExamples,
    required this.legitExamples,
    required this.truePositives,
    required this.falsePositives,
    required this.trueNegatives,
    required this.falseNegatives,
    required this.typeAccuracy,
    required this.countsByType,
  });

  final int totalExamples;
  final int scamExamples;
  final int legitExamples;
  final int truePositives;
  final int falsePositives;
  final int trueNegatives;
  final int falseNegatives;

  /// Parmi les arnaques bien détectées, proportion du bon type identifié.
  final double typeAccuracy;
  final Map<ScamType, int> countsByType;

  double get precision =>
      truePositives + falsePositives == 0 ? 0 : truePositives / (truePositives + falsePositives);
  double get recall =>
      truePositives + falseNegatives == 0 ? 0 : truePositives / (truePositives + falseNegatives);
  double get f1 =>
      precision + recall == 0 ? 0 : 2 * precision * recall / (precision + recall);
  double get accuracy => totalExamples == 0
      ? 0
      : (truePositives + trueNegatives) / totalExamples;
}
