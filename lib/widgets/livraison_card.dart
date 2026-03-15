import 'package:flutter/material.dart';
import '../models/livraison.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';

class LivraisonCard extends StatelessWidget {
  final LivraisonLivreur livraison;
  final VoidCallback? onActionPressed;
  final VoidCallback? onActionPressedColis;
  final VoidCallback? onActionPressedAnnulerColis;

  const LivraisonCard({
    super.key,
    required this.livraison,
    this.onActionPressed,
    this.onActionPressedColis,
    this.onActionPressedAnnulerColis,
  });

  Color getStatusColor(String? status) {
    switch (status) {
      case 'DEMANDE':
        return Colors.orange;
      case 'ACCEPTE':
        return Colors.green;
      case 'PRIS_PAR_LIVREUR':
        return Colors.blue;
      case 'LIVRE':
        return Colors.green.shade800;
      case 'ANNULE':
        return Colors.red;
      case 'EN_ATTENTE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00353F),
      ),
    );
  }

  Future<void> _callPhone(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack(context, "Numéro de téléphone indisponible");
      return;
    }
    final uri = Uri.parse('tel:${phone.trim()}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack(context, "Impossible d'appeler ce numéro");
    }
  }

  Future<void> _openWhatsApp(String numero) async {
    final url = Uri.parse("https://wa.me/221$numero");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String formatDate(DateTime? date) =>
      date == null ? '---' : DateFormat('EEEE d MMMM', 'fr_FR').format(date);
  String formatHeure(DateTime? date) =>
      date == null ? '---' : DateFormat('HH:mm').format(date);

  // Widget réutilisable pour les lignes de téléphone
  Widget _buildPhoneActionRow(
    BuildContext context,
    String label,
    String? phone,
    Color color,
  ) {
    if (phone == null || phone.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label: $phone",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.whatsapp, color: color, size: 20),
            onPressed: () => _openWhatsApp(phone),
          ),
          IconButton(
            icon: Icon(Icons.phone, color: color, size: 20),
            onPressed: () => _callPhone(context, phone),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = livraison;
    final bool peutVoirContacts =
        l.statusLivraison == 'ACCEPTE' ||
        l.statusLivraison == 'PRIS_PAR_LIVREUR';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau bleu foncé
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF00353F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(l.modificationDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatHeure(l.modificationDate),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Détails sur fond blanc
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- LIGNE NUMÉRO + PRIX ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Numéro : ${l.numero}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // AFFICHAGE DU PRIX SI NON NULL ET NON VIDE
                    if (l.showPrix &&
                        l.prixLivraison != null &&
                        l.prixLivraison!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE8F5E9,
                          ), // Fond vert très clair
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.shade300,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "${l.prixLivraison} FCFA",
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Description : ${l.description ?? '---'}"),
                const SizedBox(height: 4),
                Text("Départ : ${l.lieuDepart ?? '---'}"),
                Text("Arrivée : ${l.lieuArrive ?? '---'}"),

                // --- SECTION TÉLÉPHONES (Conditionnelle) ---
                if (peutVoirContacts) ...[
                  const Divider(height: 24),
                  Text(
                    "Client : ${l.nomClient ?? '---'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildPhoneActionRow(
                    context,
                    "Tél Client",
                    l.telephoneClient,
                    Colors.green,
                  ),
                  _buildPhoneActionRow(
                    context,
                    "Tél Départ",
                    l.telephoneDepart,
                    Colors.blue,
                  ),
                  _buildPhoneActionRow(
                    context,
                    "Tél Arrivée",
                    l.telephoneArrive,
                    Colors.red,
                  ),
                ],

                if ((l.commentaire ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "Commentaire :",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l.commentaire!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(l.statusLivraison),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l.libelleStatus ?? '---',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- DISTANCE VERS RAMASSAGE ---
                    if (l.distanceAffiche != null)
                      _buildDistanceIndicator(
                        icon: Icons.navigation_outlined,
                        label: "Aller chercher le colis :",
                        distance: l.distanceAffiche ?? '',
                        color: Colors.blueAccent,
                      ),

                    const SizedBox(height: 8),

                    // --- DISTANCE DU TRAJET (Ramassage -> Dest) ---
                    _buildDistanceIndicator(
                      icon: Icons.local_shipping_outlined,
                      label: "Trajet de livraison :",
                      distance: l.distanceAfficheAversB ?? '',
                      color: Colors.orange[700]!,
                    ),
                  ],
                ),
                // --- BOUTONS D'ACTIONS ---
                if (l.statusLivraison == 'ACCEPTE') ...[
                  const SizedBox(height: 12),
                  _buildButton(
                    label: "Annuler la livraison",
                    color: const Color.fromARGB(255, 194, 59, 17),
                    onTap: onActionPressedAnnulerColis,
                  ),
                  const SizedBox(height: 8),
                  _buildButton(
                    label: "Je suis en route",
                    color: const Color(0xFF00353F),
                    onTap: onActionPressed,
                  ),
                  const SizedBox(height: 8),
                  _buildButton(
                    label: "Colis Récupéré",
                    color: const Color(0xFF00353F),
                    onTap: onActionPressedColis,
                  ),
                ],

                if (l.statusLivraison == 'PRIS_PAR_LIVREUR') ...[
                  const SizedBox(height: 12),
                  _buildButton(
                    label: "Livrée",
                    color: const Color(0xFF005C6D),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/livraison-terminee',
                      arguments: l,
                    ),
                  ),
                ],

                if (l.statusLivraison == 'DEMANDE' &&
                    onActionPressed != null) ...[
                  const SizedBox(height: 16),
                  _buildButton(
                    label: "Accepter la livraison",
                    color: AppColors.primaryBlue,
                    onTap: onActionPressed,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour uniformiser les boutons
  Widget _buildButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Petit helper pour construire la ligne
  Widget _buildDistanceIndicator({
    required IconData icon,
    required String label,
    required String distance,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            distance,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
