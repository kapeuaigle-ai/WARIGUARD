/// Charge le jeu de données annoté embarqué et calcule les métriques RÉELLES
/// du moteur (précision / rappel / F1) en l'exécutant sur chaque exemple.
/// Exigence du Done MVP : « des chiffres réels, pas uniquement des promesses ».
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models.dart';
import 'detection_engine.dart';

class DatasetService {
  DatasetService._(this.examples, this.meta);

  final List<DatasetExample> examples;
  final Map<String, dynamic> meta;

  static Future<DatasetService> load() async {
    final raw = await rootBundle.loadString('assets/data/dataset_wariguard.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final examples = (json['exemples'] as List)
        .map((e) => DatasetExample.fromJson(e as Map<String, dynamic>))
        .toList();
    return DatasetService._(examples, json['meta'] as Map<String, dynamic>);
  }

  ModelMetrics evaluate(DetectionEngine engine) {
    int tp = 0, fp = 0, tn = 0, fn = 0;
    int typeCorrect = 0;
    final countsByType = <ScamType, int>{};

    for (final ex in examples) {
      countsByType.update(ex.label, (v) => v + 1, ifAbsent: () => 1);
      final result = engine.analyze(ex.text, ex.channel);
      final predictedScam = result.riskLevel != RiskLevel.vert;

      if (ex.isScam && predictedScam) {
        tp++;
        if (result.scamType == ex.label) typeCorrect++;
      } else if (ex.isScam && !predictedScam) {
        fn++;
      } else if (!ex.isScam && predictedScam) {
        fp++;
      } else {
        tn++;
      }
    }

    return ModelMetrics(
      totalExamples: examples.length,
      scamExamples: examples.where((e) => e.isScam).length,
      legitExamples: examples.where((e) => !e.isScam).length,
      truePositives: tp,
      falsePositives: fp,
      trueNegatives: tn,
      falseNegatives: fn,
      typeAccuracy: tp == 0 ? 0 : typeCorrect / tp,
      countsByType: countsByType,
    );
  }

  /// Scénarios prêts pour la démo live (un par type + un légitime).
  List<DatasetExample> demoScenarios() {
    DatasetExample pick(ScamType t, {MessageChannel? channel}) =>
        examples.firstWhere(
            (e) => e.label == t && (channel == null || e.channel == channel));
    return [
      pick(ScamType.fauxAgent, channel: MessageChannel.appel),
      pick(ScamType.fauxGain),
      pick(ScamType.transfertErrone),
      pick(ScamType.phishingLien),
      pick(ScamType.aucun),
    ];
  }
}
