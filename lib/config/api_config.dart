class ApiConfig {
  static const String host = "https://api.xamxam.ovh";
  //static const String host = "http://192.168.1.131:7310";
  static const String baseUrl = '$host/rest/mobile/livreurs';
  static const String baseUrlLogin = '$host/api/public/auth';
  static const String baseUrlParent = '$host/rest';
  //static const int positionUpdateInterval = 60; // dev
  static const int positionUpdateInterval = 180; // prod
}
