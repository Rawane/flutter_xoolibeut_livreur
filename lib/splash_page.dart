import 'package:flutter/material.dart';
import '../theme.dart'; // pour AppColors et styles

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png', // ton logo
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            // Nom de l'application ou texte
            const Text(
              'Xoolibeut',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
