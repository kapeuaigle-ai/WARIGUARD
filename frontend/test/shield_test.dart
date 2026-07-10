import 'package:flutter_test/flutter_test.dart';
import 'package:wariguard/models.dart';
import 'package:wariguard/services/detection_engine.dart';
import 'package:wariguard/services/link_shield.dart';

void main() {
  final engine = DetectionEngine();

  // Réplique la logique de AppState._buildAlert pour vérifier les boucliers.
  List<Shield> shieldsFor(String text) {
    final s = <Shield>[Shield.texte];
    if (LinkShield.extractUrls(text).isNotEmpty) s.add(Shield.lien);
    return s;
  }

  test('SMS avec lien → Bouclier Texte + Bouclier Lien, lien bloqué', () {
    const sms = 'Votre compte Orange Money doit être vérifié. '
        'Cliquez ici: http://orange-money-verification.xyz/compte';
    final shields = shieldsFor(sms);
    expect(shields, [Shield.texte, Shield.lien]);
    expect(shields.map((s) => s.label).toList(),
        ['Bouclier Texte', 'Bouclier Lien']);

    final urls = LinkShield.extractUrls(sms);
    expect(LinkShield.check(urls.first).verdict, LinkVerdict.bloque);

    final r = engine.analyze(sms, MessageChannel.sms);
    expect(r.recommendation, contains('Bouclier Lien'));
    expect(r.recommendation, isNot(contains('Link Shield')));
  });

  test('Appel sans lien → Bouclier Texte seul', () {
    const call = 'Je suis agent Wave, donnez-moi votre code de confirmation, urgent.';
    expect(shieldsFor(call), [Shield.texte]);
  });

  test('aucune recommandation ne contient de terme anglais', () {
    for (final ex in [
      'Envoyez votre code secret maintenant sinon compte bloqué',
      'Félicitations vous avez gagné, payez les frais de dossier',
      "J'ai envoyé 25 000 par erreur, renvoyez-moi l'argent",
      'Cliquez sur bit.ly/gain pour réclamer',
      'Bonjour maman, à ce soir',
    ]) {
      final r = engine.analyze(ex, MessageChannel.sms);
      expect(r.recommendation, isNot(contains('Shield')));
    }
  });
}
