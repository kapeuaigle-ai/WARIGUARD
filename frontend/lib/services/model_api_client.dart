/// Client HTTP vers le futur modèle ML de l'équipe (serveur FastAPI, backend/).
///
/// Le modèle de Cephas est en cours de développement. Dès qu'il est servi
/// derrière POST /api/analyze (contrat JSON : docs/CONTRAT_MODELE.md),
/// activer « Moteur distant » dans l'écran Sécurité : les écrans ne changent
/// pas, seul le producteur du JSON change.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

class ModelApiClient {
  ModelApiClient({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<AnalysisResult> analyze(String text, MessageChannel channel) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl/api/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'channel': channel.name}),
        )
        .timeout(const Duration(seconds: 4));
    if (resp.statusCode != 200) {
      throw Exception('API modèle: HTTP ${resp.statusCode}');
    }
    return AnalysisResult.fromJson(
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>);
  }

  Future<bool> ping() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 2));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
