import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/livraison.dart';
import '../services/livraison_service.dart';
import '../providers/livreur_provider.dart';
import '../theme.dart';
import '../widgets/custom_app_bar.dart';

class InfosLivraisonPage extends StatefulWidget {
  const InfosLivraisonPage({super.key});

  @override
  State<InfosLivraisonPage> createState() => _InfosLivraisonPageState();
}

class _InfosLivraisonPageState extends State<InfosLivraisonPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primaryBlue),
    );
  }

  Future<void> _envoyerInfo(
    LivraisonLivreur livraison,
    String numeroLivreur,
  ) async {
    if (_controller.text.trim().isEmpty) {
      _showSnack("Veuillez saisir un message");
      return;
    }

    setState(() => _loading = true);

    try {
      final service = LivraisonService();
      await service.envoyerInformation(
        numeroLivreur,
        livraison.numero,
        _controller.text.trim(),
      );

      _showSnack("Information envoyée avec succès");
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Erreur : $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final livraison =
        ModalRoute.of(context)!.settings.arguments as LivraisonLivreur;

    final numeroLivreur =
        Provider.of<LivreurProvider>(context).numeroLivreur ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Informations livraison",
        numeroLivreur: numeroLivreur,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const Text(
              "Donner une information au client ou au support",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // 📝 CHAMP TEXTE
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Ex : Je suis arrivé au point de récupération...",
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔵 BOUTON ENVOYER
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.send, color: AppColors.primaryBlue),
                label: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        "Envoyer",
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 16,
                        ),
                      ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryBlue, width: 2),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _loading
                    ? null
                    : () => _envoyerInfo(livraison, numeroLivreur),
              ),
            ),

            const SizedBox(height: 16),

            // 🔴 ANNULER
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 2),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text(
                  "Annuler",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
