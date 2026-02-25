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
        return Colors.orange; // demande en attente
      case 'ACCEPTE':
        return Colors.green; // accepté par le système / client
      case 'PRIS_PAR_LIVREUR':
        return Colors.blue; // en cours de livraison
      case 'LIVRE':
        return Colors.green.shade800; // terminé avec succès
      case 'ANNULE':
        return Colors.red; // annulé
      case 'EN_ATTENTE':
        return Colors.grey; // attente générale
      default:
        return Colors.grey;
    }
  }

  Future<void> _callPhone(String? phone, BuildContext context) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'appeler ce numéro")),
      );
    }
  }

  Future<void> _openWhatsApp(String numero) async {
    final url = Uri.parse("https://wa.me/$numero");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      const SnackBar(content: Text("Impossible d'ouvrir WhatsApp"));
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '---';
    return DateFormat('EEEE d MMMM', 'fr_FR').format(date);
  }

  String formatHeure(DateTime? date) {
    if (date == null) return '---';
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = livraison;

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
                Text(
                  "Numéro : ${l.numero}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text("Description : ${l.description ?? '---'}"),
                const SizedBox(height: 4),
                Text("Départ : ${l.lieuDepart ?? '---'}"),
                Text("Arrivée : ${l.lieuArrive ?? '---'}"),
                const SizedBox(height: 4),
                if (l.statusLivraison != 'DEMANDE') ...[
                  Text(
                    "Client : ${l.nomClient ?? '---'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        "Téléphone Client: ${l.telephoneClient ?? '---'}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      // Button WhatsApp
                      IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.green,
                        ),
                        tooltip: "Envoyer message WhatsApp",
                        onPressed: () {
                          if (l.telephoneClient != null) {
                            String tel = l.telephoneClient!;
                            _openWhatsApp('221$tel');
                          }
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        tooltip: "Appeler le client",
                        onPressed: () => _callPhone(l.telephoneClient, context),
                      ),
                    ],
                  ),
                  if ((l.telephoneDepart ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          "Téléphone Départ: ${l.telephoneDepart ?? '---'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // Button WhatsApp
                        IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.green,
                          ),
                          tooltip: "Envoyer message WhatsApp",
                          onPressed: () {
                            if (l.telephoneDepart != null) {
                              String tel = l.telephoneDepart!;
                              _openWhatsApp('221$tel');
                            }
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          tooltip: "Appeler le client",
                          onPressed: () =>
                              _callPhone(l.telephoneDepart, context),
                        ),
                      ],
                    ),
                  ],
                  if ((l.telephoneArrive ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          "Téléphone Arrivée: ${l.telephoneArrive ?? '---'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // Button WhatsApp
                        IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.green,
                          ),
                          tooltip: "Envoyer message WhatsApp",
                          onPressed: () {
                            if (l.telephoneArrive != null) {
                              String tel = l.telephoneArrive!;
                              _openWhatsApp('221$tel');
                            }
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          tooltip: "Appeler Contact Arrivé",
                          onPressed: () =>
                              _callPhone(l.telephoneArrive, context),
                        ),
                      ],
                    ),
                  ],
                ],
                if ((l.commentaire ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Commentaire :",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.commentaire!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],

                const SizedBox(height: 8),
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
                if (l.statusLivraison == 'ACCEPTE') ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => onActionPressedAnnulerColis?.call(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              194,
                              59,
                              17,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Annuler la livraison"),
                        ),
                      ),
                      // 1️⃣ Je suis en route
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => onActionPressed?.call(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00353F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Je suis en route"),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => onActionPressedColis?.call(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00353F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Colis Recupéré"),
                        ),
                      ),
                      // 2️⃣ Informations
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/infos-livraison',
                              arguments: livraison,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004A5A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Informations"),
                        ),
                      ),
                    ],
                  ),
                ],
                if (l.statusLivraison == 'PRIS_PAR_LIVREUR') ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 2️⃣ Informations
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/infos-livraison',
                              arguments: livraison,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004A5A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Informations"),
                        ),
                      ),

                      // 3️⃣ Livrée
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/livraison-terminee',
                              arguments: livraison,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005C6D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Livrée"),
                        ),
                      ),
                    ],
                  ),
                ],

                /// 🟠 BOUTON ACCEPTER LIVRAISON
                if (l.statusLivraison == 'DEMANDE' &&
                    onActionPressed != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onActionPressed!.call(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Accepter la livraison",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],

                /*if (onActionPressed != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.local_shipping,
                        color: Colors.green,
                      ),
                      tooltip: "Action",
                      onPressed: onActionPressed,
                    ),
                  ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }
}
