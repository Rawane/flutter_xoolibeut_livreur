import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:xoolibeut_livreur/utils/device_utils.dart';

class LivreurService {
  final String baseUrl = ApiConfig.baseUrl;
  final String baseUrlLogin = ApiConfig.baseUrlLogin;
  LivreurService();

  Future<String> inscrireLivreur(String codeInscription) async {
    final res = await http.post(
      Uri.parse('$baseUrl/inscription/$codeInscription'),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['numeroLivreur']; // récupère le numeroLivreur
    } else {
      throw Exception('Erreur serveur: ${res.body}');
    }
  }

  Future<void> saveTraceLivreur({
    required String numeroLivreur,
    required double? latitude,
    required double? longitude,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/traceLivreur/$numeroLivreur');

      final body = {
        "numeroLivreur": numeroLivreur,
        "latitude": latitude,
        "longitude": longitude,
        // ajoute d'autres champs ici
      };

      await http.post(
        url,
        body: jsonEncode(body),
        headers: await authHeadersValid(numeroLivreur),
      );
    } catch (e) {
      // On ne bloque pas l'utilisateur, juste log l'erreur
    }
  }

  Future<void> sendTokenFCM({
    required String numeroLivreur,
    required String? token,
    required String device,
    required String deviceId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/fcm/token/$numeroLivreur');

      final body = {
        "numeroLivreur": numeroLivreur,
        "token": token,
        "device": device,
        "deviceId": deviceId,
      };

      await http.post(
        url,
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );
    } catch (e) {
      // On ne bloque pas l'utilisateur, juste log l'erreur
    }
  }

  bool isTokenExpired(String token) {
    final parts = token.split('.');
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final exp = payload['exp'] * 1000;
    return DateTime.now().millisecondsSinceEpoch > exp;
  }

  Future<Map<String, dynamic>> fetchVersion(String version) async {
    final response = await http.get(
      Uri.parse('$baseUrl/version/control/$version'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Impossible de récupérer la version');
    }
  }
}
