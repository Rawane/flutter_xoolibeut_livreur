import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/livraison.dart';
import '../services/livraison_service.dart';
import '../providers/livreur_provider.dart';
import '../theme.dart';
import '../widgets/custom_app_bar.dart';

class LivraisonTermineePage extends StatefulWidget {
  const LivraisonTermineePage({super.key});

  @override
  State<LivraisonTermineePage> createState() => _LivraisonTermineePageState();
}

class _LivraisonTermineePageState extends State<LivraisonTermineePage> {
  bool _loading = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primaryBlue),
    );
  }

  Future<void> _terminerLivraison(
    LivraisonLivreur livraison,
    String numeroLivreur,
  ) async {
    setState(() => _loading = true);

    try {
      final service = LivraisonService();
      await service.terminerLivraison(numeroLivreur, livraison.numero);

      _showSnack("Livraison terminée avec succès !");
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/livraisonsAcceptees',
        (route) => route
            .isFirst, // Garde seulement l'accueil/index et met la liste par-dessus
      );
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
        title: "Livraison effectuée",
        numeroLivreur: numeroLivreur,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Vous confirmez que la livraison est terminée ?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // 🔵 BOUTON TERMINER
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryBlue,
                ),
                label: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        "Oui, c'est livré",
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
                    : () => _terminerLivraison(livraison, numeroLivreur),
              ),
            ),

            const SizedBox(height: 16),

            // 🔴 BOUTON ANNULER
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
