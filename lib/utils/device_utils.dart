import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xoolibeut_livreur/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:xoolibeut_livreur/services/livraison_service.dart';

final _secureStorage = FlutterSecureStorage();
final _uuid = Uuid();
final String baseUrlLogin = ApiConfig.baseUrlLogin;
Future<String> getDeviceUuid() async {
  try {
    String? uuid = await _secureStorage.read(key: 'device_uuid');
    if (uuid == null) {
      uuid = _uuid.v4();
      await _secureStorage.write(key: 'device_uuid', value: uuid);
    }
    return uuid;
  } catch (e) {
    await _secureStorage.deleteAll();
    return '';
  }
}

Future<String> getValidToken(Map<String, dynamic> data) async {
  try {
    final storedToken = await _secureStorage.read(key: 'jwt_token');
    if (storedToken != null && !isTokenExpired(storedToken)) {
      return storedToken;
    }
  } catch (e) {
    await _secureStorage.deleteAll(); // reset propre
  }

  // 🔥 Nouveau token
  final newToken = await authentLivreur(data);
  // 🔐 STOCKAGE OBLIGATOIRE
  await _secureStorage.write(
    key: 'jwt_token',
    value: newToken.trim(), // important iOS
  );

  return newToken;
}

Future<String> authentLivreur(Map<String, dynamic> data) async {
  final res = await http.post(
    Uri.parse('$baseUrlLogin/livreur/login'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  if (res.statusCode == 200) {
    final body = jsonDecode(res.body);
    return body['token'];
  } else {
    throw Exception('Erreur serveur: ${res.body}');
  }
}

// 1. Version sécurisée (évite le crash si le token est bizarre)
bool isTokenExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2)
      return true; // Token invalide -> on force la reconnexion
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );

    // On multiplie par 1000 pour passer des secondes aux millisecondes
    final int exp = payload['exp'] * 1000;
    return DateTime.now().millisecondsSinceEpoch > exp;
  } catch (e) {
    // Si une erreur survient pendant le décodage, on considère le token expiré
    return true;
  }
}

Map<String, String> authHeaders(String? token) {
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

Future<Map<String, String>> authHeadersValid(String numeroLivreur) async {
  final Map<String, dynamic> data = {
    "numeroLivreur": numeroLivreur,
    "deviceUuid": await getDeviceUuid(),
  };
  final token = await getValidToken(data);
  return authHeaders(token);
}

/// Retourne toujours une Map non nulle pour les headers HTTP
Future<Map<String, String>> getAuthHeaders() async {
  try {
    final token = await _secureStorage.read(key: 'jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  } catch (e) {
    // En cas de BadPaddingException ou autre erreur crypto, purge les données
    await _secureStorage.deleteAll();

    return {'Content-Type': 'application/json'};
  }
}

class ErrorHandler {
  static void showServiceError(BuildContext context, dynamic error) {
    String message;

    if (error is NoInternetException) {
      message = "🌐 Pas de connexion. Vérifiez votre Wi-Fi ou vos données.";
    } else if (error is RequestTimeoutException) {
      message = "⏳ Le serveur est trop lent. Veuillez réessayer.";
    } else if (error is LivreurSuspenduException) {
      message = "🚫 Compte suspendu. Contactez l'administrateur.";
      _showCriticalErrorDialog(context, message);
      return;
    } else {
      // Pour les exceptions générales throw Exception("...")
      message = error.toString().replaceFirst("Exception: ", "");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "OK",
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  static void _showCriticalErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Action Requise"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Compris"),
          ),
        ],
      ),
    );
  }
}
