import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/livraison.dart';
import '../config/api_config.dart';
import 'package:xoolibeut_livreur/utils/device_utils.dart';

/// Exception spécifique pour un livreur suspendu temporairement
class LivreurSuspenduException implements Exception {
  final String message;
  LivreurSuspenduException([
    this.message = "Votre compte est suspendu temporairement.",
  ]);
  @override
  String toString() => message;
}

class LivraisonService {
  final String baseUrl = ApiConfig.baseUrl;
  LivraisonService();

  Future<List<LivraisonLivreur>> getDemandesLivraisonPage(
    String numeroLivreur,
    String token, {
    int page = 0,
    int size = 5,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/demandes/$numeroLivreur?page=$page&size=$size',
    );
    final response = await http.get(
      uri,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200) {
      final jsonList = json.decode(response.body)['content'] as List;
      return jsonList.map((e) => LivraisonLivreur.fromJson(e)).toList();
    } else if (response.statusCode == 403) {
      throw LivreurSuspenduException();
    } else {
      throw Exception('Erreur récupération livraisons : ${response.body}');
    }
  }

  Future<List<LivraisonLivreur>> getDemandesLivraisonPageAccepte(
    String numeroLivreur,
    String token, {
    int page = 0,
    int size = 5,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/acceptes_pris/$numeroLivreur?page=$page&size=$size',
    );
    final response = await http.get(
      uri,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200) {
      final jsonList = json.decode(response.body)['content'] as List;
      return jsonList.map((e) => LivraisonLivreur.fromJson(e)).toList();
    } else if (response.statusCode == 403) {
      throw LivreurSuspenduException();
    } else {
      throw Exception('Erreur récupération livraisons : ${response.body}');
    }
  }

  Future<List<LivraisonLivreur>> getDemandesLivraisonPageLivre(
    String numeroLivreur,
    String token, {
    int page = 0,
    int size = 5,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/livres/$numeroLivreur?page=$page&size=$size',
    );
    final response = await http.get(
      uri,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200) {
      final jsonList = json.decode(response.body)['content'] as List;
      return jsonList.map((e) => LivraisonLivreur.fromJson(e)).toList();
    } else if (response.statusCode == 403) {
      throw LivreurSuspenduException();
    } else {
      throw Exception('Erreur récupération livraisons : ${response.body}');
    }
  }

  Future<LivraisonLivreur> accepterLivraison(
    String numeroLivreur,
    String numeroLivraison,
    String token,
  ) async {
    final url = Uri.parse(
      '$baseUrl/livraison/$numeroLivreur/accepter/$numeroLivraison',
    );
    final response = await http.put(
      url,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return LivraisonLivreur.fromJson(body);
    } else if (response.statusCode == 403) {
      throw LivreurSuspenduException();
    } else if (response.statusCode == 409) {
      throw Exception("DEJA_ACCEPTEE");
    } else {
      throw Exception("ERREUR_GENERALE");
    }
  }

  Future<LivraisonLivreur> annulerLivraison(
    String numeroLivreur,
    String numeroLivraison,
    String token,
  ) async {
    final url = Uri.parse(
      '$baseUrl/livraison/$numeroLivreur/annuler/$numeroLivraison',
    );
    final response = await http.put(
      url,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return LivraisonLivreur.fromJson(body);
    } else if (response.statusCode == 403) {
      throw LivreurSuspenduException();
    } else if (response.statusCode == 409) {
      throw Exception("DEJA_ACCEPTEE");
    } else {
      throw Exception("ERREUR_GENERALE");
    }
  }

  Future<LivreurDashboard> dashbordLivreur(String numeroLivreur) async {
    final url = Uri.parse('$baseUrl/$numeroLivreur/dashboard');
    final response = await http.get(
      url,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return LivreurDashboard.fromJson(body);
    } else if (response.statusCode == 403) {
      throw LivreurSuspenduException();
    } else {
      throw Exception("Impossible d'obtenir le dashboard");
    }
  }

  Future<LivraisonLivreur> changeStatusLivraison(
    String numeroLivreur,
    String numeroLivraison,
    String status,
    String token,
  ) async {
    final url = Uri.parse(
      '$baseUrl/livraison/$numeroLivreur/changestatus/$numeroLivraison/$status',
    );
    final response = await http.put(
      url,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return LivraisonLivreur.fromJson(body);
    } else if (response.statusCode == 403) {
      throw LivreurSuspenduException();
    } else {
      throw Exception("Impossible de changer le statut de la livraison");
    }
  }

  Future<void> notificationEnroute(
    String numeroLivreur,
    String numeroLivraison,
    String token,
  ) async {
    final url = Uri.parse(
      '$baseUrl/livraison/$numeroLivreur/enroute/$numeroLivraison',
    );
    final response = await http.post(
      url,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200)
      return;
    else if (response.statusCode == 403)
      throw LivreurSuspenduException();
    else
      throw Exception("Impossible d'envoyer la notification");
  }

  Future<void> terminerLivraison(
    String numeroLivreur,
    String numeroLivraison,
  ) async {
    final url = Uri.parse(
      '$baseUrl/livraison/$numeroLivreur/terminer/$numeroLivraison',
    );
    final response = await http.put(
      url,
      headers: await authHeadersValid(numeroLivreur),
    );

    if (response.statusCode == 200)
      return;
    else if (response.statusCode == 403)
      throw LivreurSuspenduException();
    else
      throw Exception("Impossible de terminer la livraison : ${response.body}");
  }

  Future<void> envoyerInformation(
    String numeroLivreur,
    String numeroLivraison,
    String message,
  ) async {
    final url = Uri.parse(
      '$baseUrl/livraison/$numeroLivreur/info/$numeroLivraison',
    );
    final response = await http.post(
      url,
      headers: await authHeadersValid(numeroLivreur),
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200)
      return;
    else if (response.statusCode == 403)
      throw LivreurSuspenduException();
    else
      throw Exception("Impossible d'envoyer l'information");
  }
}
