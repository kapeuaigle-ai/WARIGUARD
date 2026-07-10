/// Modèles WariGuard — miroir Dart du contrat JSON partagé avec le futur
/// modèle ML (voir docs/CONTRAT_MODELE.md et backend/app/schemas.py).
library;

import 'package:flutter/material.dart';

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

enum MessageChannel {
  sms('sms', 'Arnaque par SMS', Icons.sms_rounded),
  appel('appel', 'Phishing vocal', Icons.call_rounded);

  const MessageChannel(this.json, this.typeLabel, this.icon);
  final String json;
  final String typeLabel;
  final IconData icon;
}

/// Les deux boucliers de détection du MVP, en français pour la page d'alerte.
enum Shield {
  texte('Bouclier Texte', Icons.textsms_rounded),
  lien('Bouclier Lien', Icons.link_rounded);

  const Shield(this.label, this.icon);
  final String label;
  final IconData icon;
}

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

enum AlertStatus {
  blocked('Bloqué', Icons.block_rounded),
  reported('Signalé', Icons.flag_rounded),
  ignored('Ignoré', Icons.remove_circle_outline_rounded);

  const AlertStatus(this.label, this.icon);
  final String label;
  final IconData icon;

  static AlertStatus fromJson(String v) => AlertStatus.values.byName(v);
}

/// Une alerte de l'historique — produite par le vrai moteur puis chiffrée
/// localement (AES-256). Alimente la liste Alertes et l'écran de détail.
class AlertRecord {
  const AlertRecord({
    required this.id,
    required this.timestamp,
    required this.channel,
    required this.title,
    required this.riskLevel,
    required this.scamType,
    required this.riskScore,
    required this.triggers,
    required this.advice,
    required this.status,
    required this.shields,
    this.linkVerdict,
    this.linkReason,
    this.dateLabel,
  });

  final String id;
  final DateTime timestamp;
  final MessageChannel channel;
  final String title;
  final RiskLevel riskLevel;
  final ScamType scamType;
  final double riskScore;

  /// Déclencheurs lisibles (catégories renvoyées par le moteur).
  final List<String> triggers;
  final String advice;
  final AlertStatus status;

  /// Boucliers ayant détecté la menace (Texte, Lien).
  final List<Shield> shields;
  final LinkVerdict? linkVerdict;
  final String? linkReason;

  /// Libellé de date figé (pour l'historique de démonstration).
  final String? dateLabel;

  String get typeLabel => channel.typeLabel;

  String get relativeDate {
    if (dateLabel != null) return dateLabel!;
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (now.day == timestamp.day) return "Aujourd'hui, $hh:$mm";
    if (diff.inDays == 1) return 'Hier, $hh:$mm';
    return '${timestamp.day}/${timestamp.month}, $hh:$mm';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'channel': channel.json,
        'title': title,
        'risk_level': riskLevel.name,
        'scam_type': scamType.json,
        'risk_score': riskScore,
        'triggers': triggers,
        'advice': advice,
        'status': status.name,
        'shields': shields.map((s) => s.name).toList(),
        'link_verdict': linkVerdict?.name,
        'link_reason': linkReason,
        'date_label': dateLabel,
      };

  factory AlertRecord.fromJson(Map<String, dynamic> j) => AlertRecord(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        channel: MessageChannel.values.byName(j['channel'] as String),
        title: j['title'] as String,
        riskLevel: RiskLevel.fromJson(j['risk_level'] as String),
        scamType: ScamType.fromJson(j['scam_type'] as String),
        riskScore: (j['risk_score'] as num).toDouble(),
        triggers: (j['triggers'] as List).cast<String>(),
        advice: j['advice'] as String,
        status: AlertStatus.fromJson(j['status'] as String),
        shields: (j['shields'] as List)
            .map((s) => Shield.values.byName(s as String))
            .toList(),
        linkVerdict: j['link_verdict'] == null
            ? null
            : LinkVerdict.values.byName(j['link_verdict'] as String),
        linkReason: j['link_reason'] as String?,
        dateLabel: j['date_label'] as String?,
      );
}

enum ProtectionMode { automatique, aLaDemande }

/// Réglages utilisateur : permissions et modes (consentement du MVP).
class AppSettings {
  const AppSettings({
    this.onboarded = false,
    this.protection = true,
    this.micGranted = true,
    this.overlayGranted = true,
    this.mode = ProtectionMode.automatique,
    this.allowAnalysis = true,
  });

  final bool onboarded;
  final bool protection;
  final bool micGranted;
  final bool overlayGranted;
  final ProtectionMode mode;
  final bool allowAnalysis;

  bool get permMissing => !micGranted || !overlayGranted;
  bool get protectionOn => protection && !permMissing;

  AppSettings copyWith({
    bool? onboarded,
    bool? protection,
    bool? micGranted,
    bool? overlayGranted,
    ProtectionMode? mode,
    bool? allowAnalysis,
  }) =>
      AppSettings(
        onboarded: onboarded ?? this.onboarded,
        protection: protection ?? this.protection,
        micGranted: micGranted ?? this.micGranted,
        overlayGranted: overlayGranted ?? this.overlayGranted,
        mode: mode ?? this.mode,
        allowAnalysis: allowAnalysis ?? this.allowAnalysis,
      );

  Map<String, dynamic> toJson() => {
        'onboarded': onboarded,
        'protection': protection,
        'mic': micGranted,
        'overlay': overlayGranted,
        'mode': mode.name,
        'allow_analysis': allowAnalysis,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        onboarded: j['onboarded'] as bool? ?? false,
        protection: j['protection'] as bool? ?? true,
        micGranted: j['mic'] as bool? ?? true,
        overlayGranted: j['overlay'] as bool? ?? true,
        mode: ProtectionMode.values.byName(j['mode'] as String? ?? 'automatique'),
        allowAnalysis: j['allow_analysis'] as bool? ?? true,
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
