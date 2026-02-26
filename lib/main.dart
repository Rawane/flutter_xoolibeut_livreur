import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xoolibeut_livreur/providers/livreur_provider.dart';
import 'package:xoolibeut_livreur/screens/dashboard_page.dart';
import 'package:xoolibeut_livreur/screens/livraison_list_accepte.dart';
import 'package:xoolibeut_livreur/screens/livraison_list_livre.dart';
import 'package:xoolibeut_livreur/screens/inscription_page.dart';
import 'package:xoolibeut_livreur/screens/livraison_list_demandes.dart';
import 'package:xoolibeut_livreur/screens/information_livraison.dart';
import 'package:xoolibeut_livreur/screens/livraison_map_page.dart';
import 'package:xoolibeut_livreur/screens/termine_livraison.dart';
import 'package:xoolibeut_livreur/screens/resume_tabeaubord.dart';
import 'package:xoolibeut_livreur/screens/location_disclosure_page.dart';
import 'package:xoolibeut_livreur/services/livreur_service.dart';
import 'package:xoolibeut_livreur/services/livraison_service.dart';
import '../splash_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xoolibeut_livreur/services/location_foreground_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Notification channel FlutterLocalNotifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler en background FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// Son personnalisé Android
const AndroidNotificationChannel xamxamChannel = AndroidNotificationChannel(
  'xamxam_channel', // id
  'XamXam Notifications', // name
  description: 'Notifications pour XamXam livraison',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('xamxam_livraison'),
  playSound: true,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('fr_FR', null);

  // Initialisation du plugin de notifications
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(xamxamChannel);

  // Initialisation Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Optionnel : handle click
    },
  );

  final livreurService = LivreurService();
  final livraisonService = LivraisonService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LivreurProvider()),
        ChangeNotifierProvider(create: (_) => CoordonneesProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'XamXam Livraison',
        theme: ThemeData(primaryColor: const Color(0xFF00A4BD)),
        home: AppInitializer(
          livreurService: livreurService,
          livraisonService: livraisonService,
        ),
        routes: {
          '/inscription': (_) =>
              InscriptionPage(livreurService: livreurService),
          '/dashboard': (_) => DashboardPage(livreurService: livreurService),
          '/livraisons': (_) => LivraisonsDemandePage(
            livraisonService: livraisonService,
            token: 'TOKEN_FIXE_OU_RECUPERE',
          ),
          '/livraisonsAcceptees': (_) => LivraisonsAccepteesPage(
            livraisonService: livraisonService,
            token: 'TOKEN_FIXE_OU_RECUPERE',
          ),
          '/livraisonsEffectuees': (_) => LivraisonsLivrePage(
            livraisonService: livraisonService,
            token: 'TOKEN_FIXE_OU_RECUPERE',
          ),
          '/infos-livraison': (context) => InfosLivraisonPage(),
          '/livraison-terminee': (context) => LivraisonTermineePage(),
          '/map': (context) => LivraisonMapPage(
            livraisonService: livraisonService,
            token: 'TOKEN_FIXE_OU_RECUPERE',
          ),
          '/dashboard-livreur': (context) =>
              LivreurDashboardProScreen(livraisonService: livraisonService),
        },
      ),
    ),
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      _handleNotificationNavigation(message);
    }
  });

  // Foreground notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            xamxamChannel.id,
            xamxamChannel.name,
            channelDescription: xamxamChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('xamxam_livraison'),
          );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationNavigation(message);
  });
}

void _handleNotificationNavigation(RemoteMessage message) {
  final data = message.data;

  final numeroLivraison = data['numeroLivraison'];
  final lat = double.tryParse(data['lat'] ?? '');
  final lng = double.tryParse(data['lng'] ?? '');

  navigatorKey.currentState?.pushNamed(
    "/map",
    arguments: {"numeroLivraison": numeroLivraison, "lat": lat, "lng": lng},
  );
}

/// Permissions GPS
Future<void> requestLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Permissions de localisation refusées définitivement');
  }
}

/// 🔹 Wrapper qui initialise FCM et le Foreground Service après l'inscription
class AppInitializer extends StatefulWidget {
  final LivreurService livreurService;
  final LivraisonService livraisonService;

  const AppInitializer({
    super.key,
    required this.livreurService,
    required this.livraisonService,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _fcmInitialized = false;
  bool _locationServiceStarted = false;
  bool _disclosureAccepted = false;
  bool _checkedDisclosure = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkVersion();
    });
    _loadDisclosureStatus();
  }

  // Version check
  Future<void> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final versionData = await widget.livreurService.fetchVersion(
        currentVersion,
      );

      final minVersion = Platform.isAndroid
          ? versionData['minVersionAndroid']
          : versionData['minVersionIos'];
      final forceUpdate = Platform.isAndroid
          ? versionData['forceUpdateAndroid']
          : versionData['forceUpdateIos'];

      final storeUrl = Platform.isAndroid
          ? versionData['androidUrl']
          : versionData['iosUrl'];
      final message =
          versionData['message'] ?? "Une nouvelle version est disponible.";

      final isOutdated = _isVersionLower(currentVersion, minVersion);

      if (isOutdated) {
        showUpdateDialog(forceUpdate, message, storeUrl);
      }
    } catch (e) {
      print("Erreur check version: $e");
    }
  }

  bool _isVersionLower(String current, String min) {
    final currentParts = current.split('.').map(int.parse).toList();
    final minParts = min.split('.').map(int.parse).toList();

    for (int i = 0; i < minParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (currentParts[i] < minParts[i]) return true;
      if (currentParts[i] > minParts[i]) return false;
    }
    return false;
  }

  void showUpdateDialog(bool force, String message, String storeUrl) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (_) => WillPopScope(
        onWillPop: () async => !force,
        child: AlertDialog(
          title: const Text("Mise à jour disponible"),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(storeUrl);
                if (!await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                )) {
                  print("Impossible d'ouvrir le store");
                }
              },
              child: const Text("Mettre à jour"),
            ),
            if (!force)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Plus tard"),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDisclosureStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _disclosureAccepted =
          prefs.getBool('location_disclosure_accepted') ?? false;
      _checkedDisclosure = true;
    });
  }

  Future<void> _startLocationIfNeeded(String numeroLivreur) async {
    if (_locationServiceStarted) return;
    _locationServiceStarted = true;

    try {
      await requestLocationPermission();
      await startLocationService();
    } catch (_) {
      _locationServiceStarted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LivreurProvider>(
      builder: (context, livreurProvider, _) {
        if (livreurProvider.isLoading || !_checkedDisclosure) {
          return const SplashPage();
        }

        if (!_disclosureAccepted) {
          return LocationDisclosurePage(
            onAccepted: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('location_disclosure_accepted', true);
              if (!mounted) return;
              setState(() {
                _disclosureAccepted = true;
              });
            },
          );
        }

        final numeroLivreur = livreurProvider.numeroLivreur;
        if (numeroLivreur != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startLocationIfNeeded(numeroLivreur);
          });

          return DashboardPage(livreurService: widget.livreurService);
        }

        return InscriptionPage(livreurService: widget.livreurService);
      },
    );
  }
}
