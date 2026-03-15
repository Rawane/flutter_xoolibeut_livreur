import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/livraison_service.dart';

class LivreurProvider extends ChangeNotifier {
  String? _numeroLivreur;
  bool _isLoading = true;

  String? get numeroLivreur => _numeroLivreur;
  bool get isLoading => _isLoading;

  LivreurProvider() {
    loadNumeroLivreur();
  }

  Future<void> setNumerolivreur(String numero) async {
    _numeroLivreur = numero;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('numeroLivreur', numero);
    notifyListeners();
  }

  Future<void> loadNumeroLivreur() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _numeroLivreur = prefs.getString('numeroLivreur');

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearNumeroLivreur() async {
    _numeroLivreur = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('numeroLivreur');
    notifyListeners();
  }
}

class CoordonneesProvider extends ChangeNotifier {
  double? latitude;
  double? longitude;

  void updateCoordonnees(double? lat, double? lng) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }
}

class ContactProvider extends ChangeNotifier {
  String? telephone1;
  String? telephone2;
  String? titre;
  final String baseUrl = ApiConfig.baseUrl;

  bool loading = false;
  bool loaded = false;
  String? errorMessage;

  Future<void> loadContact() async {
    if (loaded || loading) return;

    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse("$baseUrl/contact");

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        telephone1 = data["telephone1"];
        telephone2 = data["telephone2"];
        titre = data["titre"];
        loaded = true;
      } else {
        throw Exception("Erreur serveur (${response.statusCode})");
      }
    } on SocketException {
      // ✅ On utilise l'exception de livraison_service.dart
      errorMessage = "Pas de connexion internet 🌐";
      throw NoInternetException();
    } on TimeoutException {
      // ✅ On utilise l'exception de livraison_service.dart
      errorMessage = "Délai d'attente dépassé ⏳";
      throw RequestTimeoutException();
    } catch (e) {
      errorMessage = "Impossible de charger les contacts";
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void reset() {
    loaded = false;
    errorMessage = null;
    notifyListeners();
  }
}
