import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class LocationDisclosurePage extends StatelessWidget {
  final VoidCallback onAccepted;

  const LocationDisclosurePage({super.key, required this.onAccepted});

  void _onRefused(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Autorisation requise"),
        content: const Text(
          "La localisation en arrière-plan est indispensable pour utiliser "
          "XamXam Livreur.\n\n"
          "Sans cette autorisation, l’application ne peut pas fonctionner.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              SystemNavigator.pop(); // ⛔ quitte l’application
            },
            child: const Text("Quitter"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // revenir à l’écran disclosure
            },
            child: const Text("Autoriser"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Autorisation requise"),
        backgroundColor: AppColors.primaryBlue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Accès à la localisation en arrière-plan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "XamXam Livreur utilise votre localisation afin de permettre "
              "le suivi des livraisons en temps réel, même lorsque l’application "
              "est fermée ou en arrière-plan.\n\n"
              "Cette fonctionnalité est indispensable au bon fonctionnement "
              "du service de livraison.\n\n"
              "Les données de localisation sont utilisées uniquement pendant "
              "une livraison active et ne sont jamais partagées avec des tiers.",
              style: TextStyle(fontSize: 14),
            ),
            Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _onRefused(context),
                child: const Text("Refuser"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onAccepted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text("J’accepte"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
