import 'dart:async';
import 'dart:convert';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final String baseUrl = ApiConfig.baseUrl;
@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "XamXam Livreur",
      content: "Suivi de la position et présence activés",
    );
  }

  // 1. Écouter les déplacements (Distance Filter: 100m)
  // Cette partie s'occupe de la précision du trajet
  Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Se déclenche tous les 100 mètres
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: "XamXam Livreur",
        notificationText: "Suivi de trajet en cours...",
        enableWakeLock: true,
      ),
    ),
  ).listen((Position position) {
    _processAndSyncPosition(position);
  });

  // 2. Heartbeat Timer (Toutes les 6 minutes)
  // Cette partie assure la présence serveur même à l'arrêt
  Timer.periodic(const Duration(minutes: 6), (_) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      _processAndSyncPosition(position);
    } catch (e) {
      //  debugPrint("Erreur Heartbeat: $e");
    }
  });

  service.on('stopService').listen((_) {
    service.stopSelf();
  });

  return true;
}

/// Fonction de traitement globale : Sauvegarde locale + Envoi Bulk
Future<void> _processAndSyncPosition(Position pos) async {
  final prefs = await SharedPreferences.getInstance();
  final String? numeroLivreur = prefs.getString('numeroLivreur');
  if (numeroLivreur == null) return;

  // Création du point actuel
  final Map<String, dynamic> currentPos = {
    'latitude': pos.latitude,
    'longitude': pos.longitude,
    'positionDate': DateTime.now().toIso8601String(),
  };

  // Récupérer l'historique non envoyé
  List<String> offlineQueue = prefs.getStringList('offline_positions') ?? [];

  // Fusionner pour l'envoi
  List<Map<String, dynamic>> allPositions = offlineQueue
      .map((e) => jsonDecode(e) as Map<String, dynamic>)
      .toList();
  allPositions.add(currentPos);

  try {
    // Tentative d'envoi groupé (Bulk)
    final response = await http
        .post(
          Uri.parse('$baseUrl/position/$numeroLivreur'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(allPositions),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Succès : on vide le stockage local
      await prefs.remove('offline_positions');
    } else {
      // Erreur serveur : on stocke pour plus tard
      _saveLocally(prefs, offlineQueue, currentPos);
    }
  } catch (e) {
    // Pas de réseau : on stocke pour plus tard
    _saveLocally(prefs, offlineQueue, currentPos);
  }
}

void _saveLocally(
  SharedPreferences prefs,
  List<String> queue,
  Map<String, dynamic> data,
) {
  // On garde max 1000 points (sécurité mémoire)
  if (queue.length > 1000) queue.removeAt(0);
  queue.add(jsonEncode(data));
  prefs.setStringList('offline_positions', queue);
}

/// 🔹 Initialisation des notifications
Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

/// 🔹 Canal notification Android
Future<void> createNotificationChannel() async {
  const channel = AndroidNotificationChannel(
    'location_foreground',
    'Service de localisation',
    description: 'Suivi en arrière-plan de la position',
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

/// 🔹 Démarrage du service (À APPELER DEPUIS L’UI)
Future<void> startLocationService() async {
  final service = FlutterBackgroundService();

  final isRunning = await service.isRunning();
  if (isRunning) {
    //print('ℹ️ Service déjà en cours');
    return;
  }

  await initNotifications();
  await createNotificationChannel();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_foreground',
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'XamXam Livreur',
      initialNotificationContent: 'Suivi de la position activé',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onStart,
    ),
  );

  service.startService();
}

/// 🔹 Permissions (à appeler AVANT le service)
Future<void> requestLocationPermission() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    throw Exception('GPS désactivé');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Permission localisation refusée définitivement');
  }
}
