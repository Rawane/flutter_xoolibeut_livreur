import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:xoolibeut_livreur/utils/device_utils.dart';
import 'livraison_service.dart'; // Pour importer les exceptions communes

class LivreurService {
  final String baseUrl = ApiConfig.baseUrl;
  final String baseUrlParent = ApiConfig.baseUrlParent;
  final String baseUrlLogin = ApiConfig.baseUrlLogin;

  final Duration defaultTimeout = const Duration(seconds: 10);

  LivreurService();

  /// 🔹 Wrapper pour gérer les erreurs réseau communes (Internet, Timeout)
  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw RequestTimeoutException();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> inscrireLivreur(String codeInscription) async {
    return _handleRequest(() async {
      final res = await http
          .post(Uri.parse('$baseUrl/inscription/$codeInscription'))
          .timeout(defaultTimeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['numeroLivreur'];
      } else {
        throw Exception('Erreur serveur: ${res.body}');
      }
    });
  }

  /// 📍 Pour la trace GPS, on utilise un try-catch silencieux car c'est une
  /// tâche de fond qui ne doit pas interrompre l'expérience utilisateur.
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
      };

      await http
          .post(
            url,
            body: jsonEncode(body),
            headers: await authHeadersValid(numeroLivreur),
          )
          .timeout(
            const Duration(seconds: 5),
          ); // Timeout plus court pour la trace
    } catch (e) {
      print("Trace GPS non envoyée (silencieux) : $e");
    }
  }

  /// 🔔 Envoi du token FCM
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

      await http
          .post(
            url,
            body: jsonEncode(body),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(defaultTimeout);
    } catch (e) {
      print("Token FCM non envoyé : $e");
    }
  }

  /// 🔑 Vérification locale de l'expiration du token
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'] * 1000;
      return DateTime.now().millisecondsSinceEpoch > exp;
    } catch (e) {
      return true;
    }
  }

  /// 🚀 Vérification de version (Indispensable au démarrage)
  Future<Map<String, dynamic>> fetchVersion(String version) async {
    return _handleRequest(() async {
      final response = await http
          .get(Uri.parse('$baseUrlParent/livreurs/version/control/$version'))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Impossible de récupérer la version');
      }
    });
  }
}
