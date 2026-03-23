import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../theme.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/livreur_provider.dart';
import '../services/livreur_service.dart';
import '../services/location_foreground_service.dart';
import '../utils/device_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.livreurService});
  final LivreurService livreurService;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static bool _alreadyCalled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ContactProvider>().loadContact();
      _initFirebaseMessaging();
    });
  }

  // --- LOGIQUE MÉTIER ---

  void _initFirebaseMessaging() async {
    if (_alreadyCalled) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();

      if (!mounted) return;
      final numeroLivreur = context.read<LivreurProvider>().numeroLivreur;
      if (numeroLivreur == null) return;

      final deviceUuid = await getDeviceUuid();
      final deviceName = await _getDeviceModel();

      _alreadyCalled = true;
      await widget.livreurService.sendTokenFCM(
        numeroLivreur: numeroLivreur,
        token: token,
        device: deviceName,
        deviceId: deviceUuid,
      );

      final data = {"numeroLivreur": numeroLivreur, "deviceUuid": deviceUuid};
      await getValidToken(data);
    } catch (_) {}
  }

  Future<String> _getDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) return (await deviceInfo.androidInfo).model;
    if (Platform.isIOS) return (await deviceInfo.iosInfo).utsname.machine;
    return "Unknown Device";
  }

  Future<void> _handleStartService() async {
    try {
      await requestLocationPermission();
      await startLocationService();
      _showSnack("Suivi de position activé");
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  // --- ACTIONS DE NAVIGATION ET UTILS ---

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primaryBlue),
    );
  }

  Future<void> _launchExternal(String url, String errorMsg) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack(errorMsg);
    }
  }

  // --- WIDGETS COMPOSANTS ---

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? iconColor,
    bool isPrimary = false,
  }) {
    final Color mainColor = isPrimary ? Colors.green : AppColors.primaryBlue;
    final style = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          )
        : OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primaryBlue, width: 2),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );

    final content = [
      Icon(icon, color: isPrimary ? Colors.white : (iconColor ?? mainColor)),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: isPrimary ? Colors.white : mainColor,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: content,
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: content,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final livreur = context.watch<LivreurProvider>();
    final contact = context.watch<ContactProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Mon Espace',
        numeroLivreur: livreur.numeroLivreur ?? '',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMenuButton(
                      icon: Icons.play_circle_fill,
                      label: "Démarrer le service",
                      isPrimary: true,
                      onPressed: _handleStartService,
                    ),
                    _buildMenuButton(
                      icon: Icons.notifications_active,
                      label: "Demandes en cours",
                      onPressed: () =>
                          Navigator.pushNamed(context, '/livraisons'),
                    ),
                    _buildMenuButton(
                      icon: Icons.local_shipping,
                      iconColor: Colors.red,
                      label: "Acceptées/Suivies",
                      onPressed: () =>
                          Navigator.pushNamed(context, '/livraisonsAcceptees'),
                    ),
                    _buildMenuButton(
                      icon: Icons.task_alt,
                      label: "Livraisons effectuées",
                      onPressed: () =>
                          Navigator.pushNamed(context, '/livraisonsEffectuees'),
                    ),
                    _buildMenuButton(
                      icon: Icons.leaderboard,
                      label: "Mes chiffres",
                      onPressed: () =>
                          Navigator.pushNamed(context, '/dashboard-livreur'),
                    ),
                    _buildMenuButton(
                      icon: Icons.explore_outlined,
                      label: "Voir sur la carte",
                      onPressed: () => Navigator.pushNamed(context, '/map'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContactSection(contact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(ContactProvider contact) {
    if (contact.loading && !contact.loaded)
      return const Center(child: CircularProgressIndicator());
    if (!contact.loaded) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
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
          _contactRow(Icons.phone, contact.telephone1 ?? ''),
          _contactRow(Icons.phone_android, contact.telephone2 ?? ''),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  "Appeler",
                  Icons.call,
                  Colors.green,
                  () => _launchExternal(
                    'tel:${contact.telephone2}',
                    "Impossible d'appeler",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  "WhatsApp",
                  FontAwesomeIcons.whatsapp,
                  Colors.teal,
                  () => _launchExternal(
                    "https://wa.me/221${contact.telephone1?.replaceAll(RegExp(r'\D'), '')}",
                    "WhatsApp non disponible",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 6),
        Text(text),
      ],
    ),
  );

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback tap,
  ) => ElevatedButton.icon(
    icon: Icon(icon, color: Colors.white, size: 18),
    label: Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    onPressed: tap,
  );
}
