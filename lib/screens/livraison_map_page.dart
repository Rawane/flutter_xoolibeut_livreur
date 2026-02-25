import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/livreur_provider.dart';
import '../services/livraison_service.dart';
import '../models/livraison.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:collection/collection.dart';

class LivraisonMapPage extends StatefulWidget {
  final LivraisonService livraisonService;
  final String token;

  const LivraisonMapPage({
    super.key,
    required this.livraisonService,
    required this.token,
  });

  @override
  State<LivraisonMapPage> createState() => _LivraisonMapPageState();
}

class _LivraisonMapPageState extends State<LivraisonMapPage> {
  LatLng? _position;
  List<LivraisonLivreur> _livraisons = [];
  late final MapController _mapController;
  String? _highlightedNumeroLivraison;
  double? _highlightedLat;
  double? _highlightedLng;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _highlightedNumeroLivraison = args['numeroLivraison'];
      _highlightedLat = args['lat'];
      _highlightedLng = args['lng'];
      // Si les livraisons sont déjà chargées, ouvrir le highlight
      if (_livraisons.isNotEmpty) {
        _openHighlightedLivraisonIfNeeded();
      }
    }
  }

  Future<void> _initMap() async {
    await _loadPosition();
    await _loadLivraisons();
  }

  Future<void> _loadPosition() async {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 15),
      ),
    );
    setState(() {
      _position = LatLng(pos.latitude, pos.longitude);
    });
  }

  Future<void> _loadLivraisons() async {
    final numeroLivreur = context.read<LivreurProvider>().numeroLivreur;
    if (numeroLivreur == null) return;

    final demandes = await widget.livraisonService.getDemandesLivraisonPage(
      numeroLivreur,
      widget.token,
      page: 0,
      size: 50,
    );

    final acceptees = await widget.livraisonService
        .getDemandesLivraisonPageAccepte(
          numeroLivreur,
          widget.token,
          page: 0,
          size: 5,
        );

    setState(() {
      _livraisons = [...demandes, ...acceptees];
    });
    _openHighlightedLivraisonIfNeeded();
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    /// 📍 Ma position
    if (_position != null) {
      markers.add(
        Marker(
          point: LatLng(_position!.latitude, _position!.longitude),
          width: 40,
          height: 40,
          child: const Icon(Icons.motorcycle, color: Colors.red, size: 40),
        ),
      );
    }

    /// 📦 Livraisons
    for (final l in _livraisons) {
      if (l.latitudeRamassage == null || l.longitudeRamassage == null) continue;
      if (l.latitudeDestinataire == null || l.longitudeDestinataire == null)
        continue;
      double lat = l.latitudeRamassage!;
      double lon = l.longitudeRamassage!;
      if (l.statusLivraison == 'PRIS_PAR_LIVREUR') {
        lat = l.latitudeDestinataire!;
        lon = l.longitudeDestinataire!;
      }
      final isHighlighted = l.numero == _highlightedNumeroLivraison;

      markers.add(
        Marker(
          point: LatLng(lat, lon),
          width: isHighlighted ? 60 : 40,
          height: isHighlighted ? 60 : 40,
          child: GestureDetector(
            onTap: () => _showLivraisonDetails(l),
            child: Icon(
              Icons.location_on,
              color: isHighlighted
                  ? Colors.red
                  : l.statusLivraison == 'DEMANDE'
                  ? Colors.orange
                  : l.statusLivraison == 'ACCEPTE'
                  ? Colors.green
                  : Colors.blue,
              size: isHighlighted ? 50 : 40,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  void _showLivraisonDetails(LivraisonLivreur livraison) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Titre
              Text(
                "Détails de la livraison",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              /// 📦 Infos
              _infoRow("Numéro ", livraison.numero),
              if (livraison.statusLivraison != 'DEMANDE') ...[
                _infoRow("Client ", livraison.nomClient ?? ""),
                _infoRowWithActions(
                  context,
                  "Téléphone Client",
                  livraison.telephoneClient,
                ),
                _infoRow("Départ", livraison.lieuDepart ?? "-"),
                if ((livraison.telephoneDepart ?? '').trim().isNotEmpty)
                  _infoRowWithActions(
                    context,
                    "Téléphone Contact Départ",
                    livraison.telephoneDepart,
                  ),

                _infoRow("Arrivée", livraison.lieuArrive ?? "-"),
                if ((livraison.telephoneDepart ?? '').trim().isNotEmpty)
                  _infoRowWithActions(
                    context,
                    "Téléphone Contact Départ",
                    livraison.telephoneDepart,
                  ),
              ],
              _infoRow("Description", livraison.description ?? "-"),
              const SizedBox(height: 20),

              /// 🔘 Actions
              _buildActionButtons(livraison),
            ],
          ),
        );
      },
    );
  }

  void _openHighlightedLivraisonIfNeeded() {
    if (_highlightedNumeroLivraison == null) return;

    final livraison = _livraisons.firstWhereOrNull(
      (l) => l.numero == _highlightedNumeroLivraison,
    );

    double lat, lon;

    if (livraison != null) {
      // Livraison trouvée dans la liste
      lat = livraison.statusLivraison == 'PRIS_PAR_LIVREUR'
          ? livraison.latitudeDestinataire!
          : livraison.latitudeRamassage!;
      lon = livraison.statusLivraison == 'PRIS_PAR_LIVREUR'
          ? livraison.longitudeDestinataire!
          : livraison.longitudeRamassage!;
    } else if (_highlightedLat != null && _highlightedLng != null) {
      // Livraison non encore dans la liste, on utilise les coordonnées de notification
      lat = _highlightedLat!;
      lon = _highlightedLng!;
    } else {
      return; // rien à afficher
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _mapController.move(LatLng(lat, lon), 16);

      if (livraison != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          _showLivraisonDetails(livraison);
        });
      }
    });

    setState(() {}); // pour redraw les markers highlight
  }

  Widget _infoRowWithActions(
    BuildContext context,
    String label,
    String? phone,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(phone ?? "-", style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),

          if (phone != null && phone.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () => _callPhone(context, phone),
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
              onPressed: () => _openWhatsApp('221$phone'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _callPhone(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack("Impossible d'appeler ce numéro");
    }
  }

  Future<void> _openWhatsApp(String numero) async {
    final url = Uri.parse("https://wa.me/$numero");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack("Impossible d'ouvrir WhatsApp");
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primaryBlue),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label :",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LivraisonLivreur livraison) {
    switch (livraison.statusLivraison) {
      case 'DEMANDE':
        return _actionButton(
          "Accepter la livraison",
          Icons.check_circle,
          Colors.green,
          () => _changerStatut(livraison, 'ACCEPTE'),
        );

      case 'ACCEPTE':
        return _actionButton(
          "Colis recupéré",
          Icons.motorcycle,
          Colors.blue,
          () => _changerStatut(livraison, 'PRIS_PAR_LIVREUR'),
        );

      case 'PRIS_PAR_LIVREUR':
        return _actionButton(
          "Marquer comme livrée",
          Icons.done_all,
          Colors.green.shade800,
          () => _changerStatut(livraison, 'LIVRE'),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _changerStatut(
    LivraisonLivreur livraison,
    String nouveauStatut,
  ) async {
    final numeroLivreur = Provider.of<LivreurProvider>(
      context,
      listen: false,
    ).numeroLivreur;

    if (numeroLivreur == null) {
      throw "Numéro livreur introuvable";
    }
    await widget.livraisonService.changeStatusLivraison(
      numeroLivreur,
      livraison.numero,
      nouveauStatut,
      widget.token,
    );

    Navigator.pop(context);
    await _loadLivraisons();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_position == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Carte des livraisons")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          //initialCenter: LatLng(14.4200, -16.9700),
          initialCenter: LatLng(_position!.latitude, _position!.longitude),
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.xamxam.livreur',
          ),
          MarkerLayer(markers: _buildMarkers()),
        ],
      ),
    );
  }
}
