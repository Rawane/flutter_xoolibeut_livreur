import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

final _secureStorage = FlutterSecureStorage();
final _uuid = Uuid();

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
