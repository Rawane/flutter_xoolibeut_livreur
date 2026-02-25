import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xoolibeut_livreur/services/livreur_service.dart';
import 'package:xoolibeut_livreur/services/location_foreground_service.dart';
import '../theme.dart';
import '../widgets/custom_app_bar.dart';
import 'package:xoolibeut_livreur/utils/device_utils.dart';
import '../providers/livreur_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DashboardPage extends StatefulWidget {
  DashboardPage({super.key, required this.livreurService});
  final LivreurService livreurService;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double? latitude;
  double? longitude;
  static bool _alreadyCalled = false;
  @override
  void initState() {
    super.initState();
    // Appels non bloquants
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<ContactProvider>(context, listen: false).loadContact();
      _initFirebaseMessaging();
    });
  }

  void _safeNavigate(String route) {
    if (!mounted) return;
    Navigator.of(context).pushNamed(route);
  }

  Future<String?> authenticate(String numeroLivreur) async {
    final deviceUuid = await getDeviceUuid();
    final Map<String, dynamic> data = {
      "numeroLivreur": numeroLivreur,
      "deviceUuid": deviceUuid,
    }; // 🔥 récupère l'UUID sécurisé
    final token = await widget.livreurService.getValidToken(data);

    return token;
  }

  Future<void> _startTrackingService() async {
    try {
      await requestLocationPermission();
      await startLocationService();

      if (!mounted) return;
      _showSnack("Suivi de position activé");
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    }
  }

  void _initFirebaseMessaging() async {
    if (_alreadyCalled) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (!mounted) return;

      final livreurProvider = context.read<LivreurProvider>();
      final numeroLivreur = livreurProvider.numeroLivreur;
      if (numeroLivreur == null) return;

      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceName = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.utsname.machine;
      }

      final deviceUuid = await getDeviceUuid();

      _alreadyCalled = true;
      await sendTokenANdAuthentificate(
        numeroLivreur,
        token,
        deviceName,
        deviceUuid,
      );
    } catch (_) {
      // silencieux en prod (no print)
    }
  }

  Future<void> sendTokenANdAuthentificate(
    String numeroLivreur,
    String? fcmToken,
    String deviceName,
    String deviceId,
  ) async {
    await widget.livreurService.sendTokenFCM(
      numeroLivreur: numeroLivreur,
      token: fcmToken,
      device: deviceName,
      deviceId: deviceId,
    );
    await authenticate(numeroLivreur);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primaryBlue),
    );
  }

  Widget _buildContactSection(ContactProvider contact, BuildContext context) {
    if (contact.loading && !contact.loaded) {
      return Center(child: CircularProgressIndicator());
    }
    if (!contact.loaded) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.titre ?? "",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.phone, color: Colors.green, size: 20),
              const SizedBox(width: 6),
              Text(contact.telephone1 ?? ''),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.phone_android, color: Colors.green, size: 20),
              const SizedBox(width: 6),
              Text(contact.telephone2 ?? ''),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.call, color: Colors.white),
                  label: Text(
                    "Appeler",
                    style: TextStyle(
                      color: Colors.white, // 👈 écriture blanche
                      fontSize: 14,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final numero = contact.telephone2;
                    if (numero != null && numero.isNotEmpty) {
                      _callPhone(context, numero);
                    } else {
                      _showSnack("Numéro de téléphone indisponible");
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                  label: Text(
                    "WhatsApp",
                    style: TextStyle(
                      color: Colors.white, // 👈 écriture blanche
                      fontSize: 14,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final numero = contact.telephone1;
                    if (numero != null && numero.isNotEmpty) {
                      _openWhatsApp('221$numero');
                    } else {
                      _showSnack("Numéro WhatsApp indisponible");
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack("Numéro de téléphone indisponible");
      return;
    }

    final uri = Uri.parse('tel:${phone.trim()}');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack("Impossible d'appeler ce numéro");
    }
  }

  Future<void> _openWhatsApp(String numero) async {
    final clean = numero.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      _showSnack("Numéro WhatsApp indisponible");
      return;
    }

    final uri = Uri.parse("https://wa.me/$clean");

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack("WhatsApp non disponible");
    }
  }

  void _openMapPage() {
    Navigator.pushNamed(context, '/map');
  }

  void _openTableauBord() {
    Navigator.pushNamed(context, '/dashboard-livreur');
  }

  @override
  Widget build(BuildContext context) {
    final livreurProvider = Provider.of<LivreurProvider>(context);
    final contact = context.watch<ContactProvider>();
    final numeroLivreur = livreurProvider.numeroLivreur;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Mon Espace',
        numeroLivreur: numeroLivreur ?? '',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.gps_fixed, color: Colors.white),
                        label: const Text(
                          "Démarrer le suivi",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _startTrackingService,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Demandes en cours
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.delivery_dining,
                          color: AppColors.primaryBlue,
                        ),
                        label: Text(
                          'Demandes en cours',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _safeNavigate('/livraisons'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.map_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        label: Text(
                          'Voir sur la carte',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _openMapPage,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Livraisons acceptées
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.assignment_turned_in,
                          color: AppColors.primaryBlue,
                        ),
                        label: Text(
                          'Acceptées/Acheminement en cours',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/livraisonsAcceptees',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Livraisons effectuées
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primaryBlue,
                        ),
                        label: Text(
                          'Livraisons effectuées',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/livraisonsEffectuees',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.map_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        label: Text(
                          'Mes chiffres',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _openTableauBord,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _buildContactSection(contact, context),
            ),
          ],
        ),
      ),
    );
  }
}
