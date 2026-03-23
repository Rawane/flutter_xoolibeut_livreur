/// ❌ Exception : Pas d'internet
class NoInternetException implements Exception {
  @override
  String toString() => "Pas de connexion internet. Vérifiez votre réseau.";
}

/// ❌ Exception : Serveur trop long à répondre
class RequestTimeoutException implements Exception {
  @override
  String toString() => "Le serveur met trop de temps à répondre. Réessayez.";
}

/// ❌ Exception : Livreur suspendu
class LivreurSuspenduException implements Exception {
  final String message;
  LivreurSuspenduException([
    this.message = "Votre compte est suspendu temporairement.",
  ]);
  @override
  String toString() => message;
}
