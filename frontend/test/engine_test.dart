import 'package:flutter_test/flutter_test.dart';
import 'package:wariguard/models.dart';
import 'package:wariguard/services/detection_engine.dart';
import 'package:wariguard/services/link_shield.dart';

void main() {
  final engine = DetectionEngine();

  group('Text Shield — moteur heuristique', () {
    test('faux agent demandant un code → rouge', () {
      final r = engine.analyze(
        'Cher client Orange Money, votre compte sera bloqué. Envoyez votre code secret maintenant.',
        MessageChannel.sms,
      );
      expect(r.riskLevel, RiskLevel.rouge);
      expect(r.scamType, ScamType.fauxAgent);
      expect(r.triggers, isNotEmpty);
    });

    test('faux gain avec frais → alerte', () {
      final r = engine.analyze(
        'FÉLICITATIONS! Vous avez gagné 500 000 FCFA à la tombola. Payez les frais de dossier pour réclamer votre lot.',
        MessageChannel.sms,
      );
      expect(r.riskLevel, isNot(RiskLevel.vert));
      expect(r.scamType, ScamType.fauxGain);
    });

    test('transfert erroné → alerte', () {
      final r = engine.analyze(
        "J'ai envoyé 25 000 FCFA par erreur sur votre numéro, renvoyez-moi l'argent vite svp.",
        MessageChannel.sms,
      );
      expect(r.riskLevel, isNot(RiskLevel.vert));
      expect(r.scamType, ScamType.transfertErrone);
    });

    test('message légitime → vert', () {
      final r = engine.analyze(
        'Maman a dit de passer prendre le riz chez tantie Awa après le travail.',
        MessageChannel.sms,
      );
      expect(r.riskLevel, RiskLevel.vert);
      expect(r.scamType, ScamType.aucun);
    });

    test('reçu de transaction légitime → vert', () {
      final r = engine.analyze(
        'Vous avez reçu 10 000 FCFA de KOUAME YAO. Nouveau solde: 45 200 FCFA. Ref: PP260708.1422.',
        MessageChannel.sms,
      );
      expect(r.riskLevel, RiskLevel.vert);
    });

    test('contrat JSON — round-trip sans perte', () {
      final r = engine.analyze('Envoyez votre code PIN maintenant, urgent!', MessageChannel.appel);
      final restored = AnalysisResult.fromJson(r.toJson());
      expect(restored.riskScore, r.riskScore);
      expect(restored.riskLevel, r.riskLevel);
      expect(restored.scamType, r.scamType);
      expect(restored.triggers.length, r.triggers.length);
    });
  });

  group('Link Shield', () {
    test('typosquatting opérateur → bloqué', () {
      final r = LinkShield.check('http://orange-money-verification.xyz/compte');
      expect(r.verdict, LinkVerdict.bloque);
      expect(r.reasons, isNotEmpty);
    });

    test('raccourcisseur → au moins suspect', () {
      final r = LinkShield.check('bit.ly/mtn-gain');
      expect(r.verdict, isNot(LinkVerdict.sur));
    });

    test('adresse IP brute → bloqué', () {
      final r = LinkShield.check('http://185.22.14.8/mtn-update.apk');
      expect(r.verdict, LinkVerdict.bloque);
    });

    test('domaine officiel → sûr', () {
      final r = LinkShield.check('https://wave.com');
      expect(r.verdict, LinkVerdict.sur);
    });

    test('extraction d\'URLs dans un SMS', () {
      final urls = LinkShield.extractUrls(
          'Cliquez ici: http://orange-money-verification.xyz/compte pour vérifier');
      expect(urls, isNotEmpty);
    });
  });
}
