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

/// 🔹 Fonction exécutée par le service background
@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "XamXam Livreur",
      content: "Suivi de la position en cours",
    );
  }

  Timer? timer;

  service.on('stopService').listen((_) {
    timer?.cancel();
    service.stopSelf();
  });

  timer = Timer.periodic(Duration(seconds: ApiConfig.positionUpdateInterval), (
    _,
  ) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final numeroLivreur = prefs.getString('numeroLivreur') ?? 'unknown';

      await http.post(
        Uri.parse('$baseUrl/v2/position/$numeroLivreur'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  });

  return true;
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
