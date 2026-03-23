import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xoolibeut_livreur/utils/exception_xoolibeut.dart';
import '../models/livraison.dart';
import '../config/api_config.dart';
import 'package:xoolibeut_livreur/utils/device_utils.dart';
import 'package:geolocator/geolocator.dart';

class LivraisonService {
  final String baseUrl = ApiConfig.baseUrl;
  final Duration defaultTimeout = const Duration(seconds: 10);

  LivraisonService();

  /// 🔹 Méthode privée pour centraliser la capture GPS
  Future<Position?> _getCurrentLocation() async {
    try {
      // 1. On vérifie si le service GPS est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // 2. On augmente le temps à 12 secondes pour être réaliste
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Medium est parfait pour la ville
          timeLimit: Duration(seconds: 12), // <--- On passe à 12s
        ),
      ).timeout(
        const Duration(seconds: 13),
        onTimeout: () {
          throw 'Timeout atteint'; // Sécurité supplémentaire
        },
      );
    } catch (e) {
      //debugPrint("Erreur capture GPS (souvent Timeout) : $e");
      // Astuce : Tenter de récupérer la dernière position connue si le scan actuel échoue
      // C'est mieux que 0,0 !
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

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

  Future<List<LivraisonLivreur>> getDemandesLivraisonPage(
    String numeroLivreur,
    String token, {
    int page = 0,
    int size = 5,
  }) async {
    return _handleRequest(() async {
      // 1. On tente d'obtenir la position (avec notre timeout de 12s et secours LastKnown)
      Position? position = await _getCurrentLocation();

      // 2. On prépare les coordonnées (si null, on garde 0,0 mais c'est rare avec le secours)
      final double lat = position?.latitude ?? 0;
      final double lon = position?.longitude ?? 0;

      final uri = Uri.parse(
        '$baseUrl/demandes/$numeroLivreur?page=$page&size=$size&lat=$lat&lon=$lon',
      );

      final response = await http
          .get(uri, headers: await authHeadersValid(numeroLivreur))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final jsonList = json.decode(response.body)['content'] as List;
        return jsonList.map((e) => LivraisonLivreur.fromJson(e)).toList();
      } else if (response.statusCode == 403) {
        throw LivreurSuspenduException();
      } else {
        throw Exception('Erreur récupération livraisons : ${response.body}');
      }
    });
  }

  Future<List<LivraisonLivreur>> getDemandesLivraisonPageAccepte(
    String numeroLivreur,
    String token, {
    int page = 0,
    int size = 5,
  }) async {
    return _handleRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/acceptes_pris/$numeroLivreur?page=$page&size=$size',
      );
      final response = await http
          .get(uri, headers: await authHeadersValid(numeroLivreur))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final jsonList = json.decode(response.body)['content'] as List;
        return jsonList.map((e) => LivraisonLivreur.fromJson(e)).toList();
      } else if (response.statusCode == 403) {
        throw LivreurSuspenduException();
      } else {
        throw Exception('Erreur récupération livraisons : ${response.body}');
      }
    });
  }

  Future<List<LivraisonLivreur>> getDemandesLivraisonPageLivre(
    String numeroLivreur,
    String token, {
    int page = 0,
    int size = 5,
  }) async {
    return _handleRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/livres/$numeroLivreur?page=$page&size=$size',
      );
      final response = await http
          .get(uri, headers: await authHeadersValid(numeroLivreur))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final jsonList = json.decode(response.body)['content'] as List;
        return jsonList.map((e) => LivraisonLivreur.fromJson(e)).toList();
      } else if (response.statusCode == 403) {
        throw LivreurSuspenduException();
      } else {
        throw Exception('Erreur récupération livraisons : ${response.body}');
      }
    });
  }

  Future<LivraisonLivreur> accepterLivraison(
    String numeroLivreur,
    String numeroLivraison,
    String token,
  ) async {
    return _handleRequest(() async {
      Position? position = await _getCurrentLocation();
      final url = Uri.parse(
        '$baseUrl/livraison/$numeroLivreur/accepter/$numeroLivraison?lat=${position?.latitude ?? 0}&lon=${position?.longitude ?? 0}',
      );

      final response = await http
          .put(url, headers: await authHeadersValid(numeroLivreur))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return LivraisonLivreur.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 417) {
        final errorBody = jsonDecode(response.body);
        throw Exception("TROP_LOIN:${errorBody['distanceLabel'] ?? ''}");
      } else if (response.statusCode == 403) {
        throw LivreurSuspenduException();
      } else if (response.statusCode == 409) {
        throw Exception("DEJA_ACCEPTEE");
      } else {
        throw Exception("ERREUR_GENERALE");
      }
    });
  }

  Future<LivraisonLivreur> annulerLivraison(
    String numeroLivreur,
    String numeroLivraison,
    String token,
  ) async {
    return _handleRequest(() async {
      final url = Uri.parse(
        '$baseUrl/livraison/$numeroLivreur/annuler/$numeroLivraison',
      );
      final response = await http
          .put(url, headers: await authHeadersValid(numeroLivreur))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        return LivraisonLivreur.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        throw LivreurSuspenduException();
      } else if (response.statusCode == 409) {
        throw Exception("DEJA_ACCEPTEE");
      } else {
        throw Exception("ERREUR_GENERALE");
      }
    });
  }

  Future<LivreurDashboard> dashbordLivreur(String numeroLivreur) async {
    return _handleRequest(() async {
      final url = Uri.parse('$baseUrl/$numeroLivreur/dashboard');
      final response = await http
          .get(url, headers: await authHeadersValid(numeroLivreur))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        return LivreurDashboard.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        throw LivreurSuspenduException();
      } else {
        throw Exception("Impossible d'obtenir le dashboard");
      }
    });
  }

  Future<LivraisonLivreur> changeStatusLivraison(
    String numeroLivreur,
    String numeroLivraison,
    String status,
    String token,
  ) async {
    return _handleRequest(() async {
      Position? position = await _getCurrentLocation();
      final url = Uri.parse(
        '$baseUrl/livraison/$numeroLivreur/changestatus/$numeroLivraison/$status?lat=${position?.latitude ?? 0}&lon=${position?.longitude ?? 0}',
      );

      final response = await http
          .put(url, headers: await authHeadersValid(numeroLivreur))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        return LivraisonLivreur.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        throw LivreurSuspenduException();
      } else {
        throw Exception("Impossible de changer le statut");
      }
    });
  }

  Future<void> notificationEnroute(
    String numeroLivreur,
    String numeroLivraison,
    String token,
  ) async {
    return _handleRequest(() async {
      Position? position = await _getCurrentLocation();
      final url = Uri.parse(
        '$baseUrl/livraison/$numeroLivreur/enroute/$numeroLivraison?lat=${position?.latitude ?? 0}&lon=${position?.longitude ?? 0}',
      );

      final response = await http
          .post(url, headers: await authHeadersValid(numeroLivreur))
          .timeout(defaultTimeout);

      if (response.statusCode == 403) throw LivreurSuspenduException();
      if (response.statusCode != 200)
        throw Exception("Impossible d'envoyer la notification");
    });
  }

  Future<void> terminerLivraison(
    String numeroLivreur,
    String numeroLivraison,
  ) async {
    return _handleRequest(() async {
      Position? position = await _getCurrentLocation();
      final url = Uri.parse(
        '$baseUrl/livraison/$numeroLivreur/terminer/$numeroLivraison?lat=${position?.latitude ?? 0}&lon=${position?.longitude ?? 0}',
      );

      final response = await http
          .put(url, headers: await authHeadersValid(numeroLivreur))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 403) throw LivreurSuspenduException();
      if (response.statusCode != 200)
        throw Exception(
          "Impossible de terminer la livraison : ${response.body}",
        );
    });
  }

  Future<void> envoyerInformation(
    String numeroLivreur,
    String numeroLivraison,
    String message,
  ) async {
    return _handleRequest(() async {
      final url = Uri.parse(
        '$baseUrl/livraison/$numeroLivreur/info/$numeroLivraison',
      );
      final response = await http
          .post(
            url,
            headers: await authHeadersValid(numeroLivreur),
            body: jsonEncode({"message": message}),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 403) throw LivreurSuspenduException();
      if (response.statusCode != 200)
        throw Exception("Impossible d'envoyer l'information");
    });
  }
}
