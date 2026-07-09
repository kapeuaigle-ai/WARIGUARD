/// État global WariGuard : consentement, historique chiffré, moteur actif.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'crypto_service.dart';
import 'dataset_service.dart';
import 'detection_engine.dart';
import 'link_shield.dart';
import 'model_api_client.dart';

enum EngineSource { local, api }

class AppState extends ChangeNotifier {
  AppState();

  static const _consentPref = 'wariguard.consent';
  static const _historyPref = 'wariguard.history.enc';

  late final SharedPreferences _prefs;
  late final CryptoService crypto;
  late final DatasetService dataset;
  final DetectionEngine engine = DetectionEngine();
  final ModelApiClient apiClient = ModelApiClient();

  bool ready = false;
  ConsentSettings consent = const ConsentSettings();
  List<HistoryEntry> history = [];
  ModelMetrics? metrics;
  EngineSource engineSource = EngineSource.local;
  bool apiAvailable = false;

  /// Dernier blob chiffré écrit — affiché comme preuve dans l'écran Sécurité.
  EncryptedBlob? lastEncryptedSample;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    crypto = await CryptoService.init();
    dataset = await DatasetService.load();
    metrics = dataset.evaluate(engine);

    final consentRaw = _prefs.getString(_consentPref);
    if (consentRaw != null) {
      consent = ConsentSettings.fromJson(jsonDecode(consentRaw) as Map<String, dynamic>);
    }
    _loadHistory();

    ready = true;
    notifyListeners();

    // Ping non bloquant du serveur modèle (optionnel pour la démo).
    apiClient.ping().then((ok) {
      apiAvailable = ok;
      notifyListeners();
    });
  }

  // ---------- Consentement ----------

  Future<void> updateConsent(ConsentSettings next) async {
    consent = next;
    await _prefs.setString(_consentPref, jsonEncode(next.toJson()));
    notifyListeners();
  }

  bool get protectionActive =>
      consent.mode != ConsentMode.desactive &&
      (consent.textShield || consent.linkShield);

  // ---------- Analyse ----------

  Future<AnalysisResult> analyzeText(String text, MessageChannel channel) async {
    AnalysisResult result;
    if (engineSource == EngineSource.api && apiAvailable) {
      try {
        result = await apiClient.analyze(text, channel);
      } catch (_) {
        // Repli local : la protection ne dépend jamais du réseau.
        result = engine.analyze(text, channel);
      }
    } else {
      result = engine.analyze(text, channel);
    }
    await _recordHistory(text, channel, result);
    return result;
  }

  LinkCheckResult checkLink(String url) => LinkShield.check(url);

  Future<void> setEngineSource(EngineSource source) async {
    if (source == EngineSource.api) {
      apiAvailable = await apiClient.ping();
    }
    engineSource = source;
    notifyListeners();
  }

  // ---------- Historique chiffré (AES-256, stockage local uniquement) ----------

  Future<void> _recordHistory(
      String text, MessageChannel channel, AnalysisResult result) async {
    final entry = HistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      timestamp: DateTime.now(),
      channel: channel,
      textPreview: text.length > 80 ? '${text.substring(0, 77)}…' : text,
      riskLevel: result.riskLevel,
      scamType: result.scamType,
      riskScore: result.riskScore,
    );
    history.insert(0, entry);
    if (history.length > 50) history = history.sublist(0, 50);
    await _persistHistory();
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    final blob = crypto.encryptJson(history.map((e) => e.toJson()).toList());
    lastEncryptedSample = blob;
    await _prefs.setString(
        _historyPref, jsonEncode({'iv': blob.iv, 'data': blob.ciphertextB64}));
  }

  void _loadHistory() {
    final raw = _prefs.getString(_historyPref);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final blob =
          EncryptedBlob(iv: j['iv'] as String, ciphertextB64: j['data'] as String);
      lastEncryptedSample = blob;
      final list = crypto.decryptJson(blob) as List;
      history = list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      history = [];
    }
  }

  Future<void> clearHistory() async {
    history = [];
    await _prefs.remove(_historyPref);
    lastEncryptedSample = null;
    notifyListeners();
  }

  // ---------- Stats dérivées ----------

  int get threatsBlocked =>
      history.where((h) => h.riskLevel == RiskLevel.rouge).length;
  int get warnings => history.where((h) => h.riskLevel == RiskLevel.orange).length;
}
