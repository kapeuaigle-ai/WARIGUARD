/// État global WariGuard : réglages/permissions, historique d'alertes chiffré
/// (AES-256), moteur de détection local. L'historique est produit par le vrai
/// moteur, pas par des données factices.
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

  static const _settingsPref = 'wariguard.settings';
  static const _historyPref = 'wariguard.alerts.enc.v2';

  late final SharedPreferences _prefs;
  late final CryptoService crypto;
  late final DatasetService dataset;
  final DetectionEngine engine = DetectionEngine();
  final ModelApiClient apiClient = ModelApiClient();

  bool ready = false;
  AppSettings settings = const AppSettings();
  List<AlertRecord> history = [];
  ModelMetrics? metrics;
  EngineSource engineSource = EngineSource.local;
  bool apiAvailable = false;

  /// Dernier blob chiffré écrit — affiché comme preuve dans l'écran données.
  EncryptedBlob? lastEncryptedSample;

  /// Alerte affichée par-dessus l'app (pop-up « écran roi »).
  AlertRecord? pendingAlert;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    crypto = await CryptoService.init();
    dataset = await DatasetService.load();
    metrics = dataset.evaluate(engine);

    final raw = _prefs.getString(_settingsPref);
    if (raw != null) {
      settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    _loadHistory();
    if (history.isEmpty) _seedHistory();

    ready = true;
    notifyListeners();

    apiClient.ping().then((ok) {
      apiAvailable = ok;
      notifyListeners();
    });
  }

  // ---------- Réglages ----------

  Future<void> updateSettings(AppSettings next) async {
    settings = next;
    await _prefs.setString(_settingsPref, jsonEncode(next.toJson()));
    notifyListeners();
  }

  Future<void> toggleProtection() =>
      updateSettings(settings.copyWith(protection: !settings.protection));
  Future<void> toggleMic() =>
      updateSettings(settings.copyWith(micGranted: !settings.micGranted));
  Future<void> toggleOverlay() =>
      updateSettings(settings.copyWith(overlayGranted: !settings.overlayGranted));
  Future<void> toggleAnalysis() =>
      updateSettings(settings.copyWith(allowAnalysis: !settings.allowAnalysis));
  Future<void> setMode(ProtectionMode mode) =>
      updateSettings(settings.copyWith(mode: mode));

  Future<void> grantPermissions() => updateSettings(
      settings.copyWith(onboarded: true, micGranted: true, overlayGranted: true));
  Future<void> skipPermissions() =>
      updateSettings(settings.copyWith(onboarded: true));

  // ---------- Analyse ----------

  Future<AnalysisResult> _analyze(String text, MessageChannel channel) async {
    if (engineSource == EngineSource.api && apiAvailable) {
      try {
        return await apiClient.analyze(text, channel);
      } catch (_) {
        return engine.analyze(text, channel);
      }
    }
    return engine.analyze(text, channel);
  }

  /// Analyse un message et construit une alerte (sans l'ajouter à l'historique).
  Future<AlertRecord> analyzeToAlert(
    String text,
    MessageChannel channel, {
    required String title,
    AlertStatus status = AlertStatus.blocked,
    String? dateLabel,
    DateTime? timestamp,
  }) async {
    final result = await _analyze(text, channel);
    return _buildAlert(
      text: text,
      channel: channel,
      title: title,
      result: result,
      status: status,
      dateLabel: dateLabel,
      timestamp: timestamp,
    );
  }

  AlertRecord _buildAlert({
    required String text,
    required MessageChannel channel,
    required String title,
    required AnalysisResult result,
    required AlertStatus status,
    String? dateLabel,
    DateTime? timestamp,
  }) {
    final shields = <Shield>[Shield.texte];
    LinkVerdict? linkVerdict;
    String? linkReason;
    final urls = LinkShield.extractUrls(text);
    if (urls.isNotEmpty) {
      shields.add(Shield.lien);
      final check = LinkShield.check(urls.first);
      linkVerdict = check.verdict;
      linkReason = check.reasons.isNotEmpty ? check.reasons.first : null;
    }
    final triggers = <String>[];
    for (final t in result.triggers) {
      final label = _capitalize(t.category);
      if (!triggers.contains(label)) triggers.add(label);
    }
    return AlertRecord(
      id: (timestamp ?? DateTime.now()).microsecondsSinceEpoch.toRadixString(36),
      timestamp: timestamp ?? DateTime.now(),
      channel: channel,
      title: title,
      riskLevel: result.riskLevel,
      scamType: result.scamType,
      riskScore: result.riskScore,
      // Cahier des charges : 2-3 déclencheurs maximum, jamais un paragraphe.
      triggers: triggers.take(3).toList(),
      advice: result.recommendation,
      status: status,
      shields: shields,
      linkVerdict: linkVerdict,
      linkReason: linkReason,
      dateLabel: dateLabel,
    );
  }

  /// Mode démo : analyse un vrai scénario d'appel frauduleux et ouvre le
  /// pop-up. Contenu et apparence identiques au pipeline réel (§3.2).
  Future<void> triggerSimulatedAlert() async {
    pendingAlert = await simulateSuspiciousCall();
    notifyListeners();
  }

  /// Ferme le pop-up. `status` null = fermeture sans décision (bouton ×).
  Future<void> dismissAlert(AlertStatus? status) async {
    final alert = pendingAlert;
    pendingAlert = null;
    notifyListeners();
    if (alert != null && status != null) await resolveAlert(alert, status);
  }

  Future<AlertRecord> simulateSuspiciousCall() {
    return analyzeToAlert(
      "Bonjour, je suis agent Wave, service vérification. Nous avons détecté une "
      "opération suspecte sur votre compte. Pour la bloquer, donnez-moi le code de "
      "confirmation que vous venez de recevoir par SMS, c'est urgent sinon votre "
      "compte sera bloqué.",
      MessageChannel.appel,
      title: 'Appel « Agent Wave — vérification »',
      status: AlertStatus.blocked,
    );
  }

  Future<void> resolveAlert(AlertRecord alert, AlertStatus status) async {
    final resolved = AlertRecord(
      id: alert.id,
      timestamp: DateTime.now(),
      channel: alert.channel,
      title: alert.title,
      riskLevel: alert.riskLevel,
      scamType: alert.scamType,
      riskScore: alert.riskScore,
      triggers: alert.triggers,
      advice: alert.advice,
      status: status,
      shields: alert.shields,
      linkVerdict: alert.linkVerdict,
      linkReason: alert.linkReason,
    );
    history.insert(0, resolved);
    if (history.length > 50) history = history.sublist(0, 50);
    await _persistHistory();
    notifyListeners();
  }

  LinkCheckResult checkLink(String url) => LinkShield.check(url);

  Future<void> setEngineSource(EngineSource source) async {
    if (source == EngineSource.api) {
      apiAvailable = await apiClient.ping();
    }
    engineSource = source;
    notifyListeners();
  }

  // ---------- Historique chiffré (AES-256, stockage local) ----------

  void _seedHistory() {
    final ex = dataset.examples;
    DatasetExample? pick(bool Function(DatasetExample) test) {
      for (final e in ex) {
        if (test(e)) return e;
      }
      return null;
    }

    final vocalAgent =
        pick((e) => e.label == ScamType.fauxAgent && e.channel == MessageChannel.appel);
    final smsLink = pick((e) =>
        e.channel == MessageChannel.sms &&
        e.isScam &&
        LinkShield.extractUrls(e.text).isNotEmpty);
    final vocalTransfert = pick(
        (e) => e.label == ScamType.transfertErrone && e.channel == MessageChannel.appel);

    final now = DateTime.now();
    final seeds = <AlertRecord>[];
    if (vocalAgent != null) {
      seeds.add(_buildAlert(
        text: vocalAgent.text,
        channel: MessageChannel.appel,
        title: 'Appel « Service client Orange »',
        result: engine.analyze(vocalAgent.text, MessageChannel.appel),
        status: AlertStatus.blocked,
        dateLabel: "Aujourd'hui, 14:32",
        timestamp: now.subtract(const Duration(hours: 2)),
      ));
    }
    if (smsLink != null) {
      seeds.add(_buildAlert(
        text: smsLink.text,
        channel: MessageChannel.sms,
        title: 'SMS « Vous avez gagné 500 000 FCFA »',
        result: engine.analyze(smsLink.text, MessageChannel.sms),
        status: AlertStatus.reported,
        dateLabel: 'Hier, 19:08',
        timestamp: now.subtract(const Duration(days: 1)),
      ));
    }
    if (vocalTransfert != null) {
      seeds.add(_buildAlert(
        text: vocalTransfert.text,
        channel: MessageChannel.appel,
        title: 'Appel « Transfert reçu par erreur »',
        result: engine.analyze(vocalTransfert.text, MessageChannel.appel),
        status: AlertStatus.ignored,
        dateLabel: '6 juil., 11:20',
        timestamp: now.subtract(const Duration(days: 4)),
      ));
    }
    history = seeds;
    _persistHistory();
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
          .map((e) => AlertRecord.fromJson(e as Map<String, dynamic>))
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
      history.where((h) => h.riskLevel != RiskLevel.vert).length;

  String get lastScanLabel => history.isEmpty ? '—' : history.first.relativeDate;

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
