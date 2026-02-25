import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xoolibeut_livreur/providers/livreur_provider.dart';
import 'package:xoolibeut_livreur/services/livreur_service.dart';
import '../theme.dart';

class InscriptionPage extends StatefulWidget {
  final LivreurService livreurService;
  const InscriptionPage({super.key, required this.livreurService});
  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _codeInscriptionController = TextEditingController();
  bool _loading = false;
  Future<void> _inscrire() async {
    if (_codeInscriptionController.text.isEmpty) {
      _showSnack("Veuillez remplir tous les champs obligatoires");
      return;
    }

    // Supprimer espaces, tirets, parenthèses...
    String codeInscription = _codeInscriptionController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    //Numero 5 Chiffres
    final regSenegal = RegExp(r'^[0-9]{5}$');

    if (!regSenegal.hasMatch(codeInscription)) {
      _showSnack("Code Inscription invalide");
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔥 1. Inscrire + récupérer numeroLivreur
      final numeroLivreur = await widget.livreurService.inscrireLivreur(
        _codeInscriptionController.text.trim(),
      );

      // 🔥 2. Sauvegarder numeroLivreur
      final livreurProvider = Provider.of<LivreurProvider>(
        context,
        listen: false,
      );
      await livreurProvider.setNumerolivreur(numeroLivreur);

      if (!mounted) return;

      _showSnack("Inscription réussie ! Votre numéro est $numeroLivreur");
    } catch (e) {
      if (!mounted) return;
      _showSnack("Erreur lors de l'inscription : $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primaryBlue),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters:
          inputFormatters ??
          (maxLength != null
              ? [LengthLimitingTextInputFormatter(maxLength)]
              : null),
      style: const TextStyle(color: Colors.black87),
      cursorColor: AppColors.primaryBlue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.accentBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription', style: AppTextStyles.titleBoldWhite),
        backgroundColor: AppColors.primaryBlue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: AppColors.secondaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField(
                  _codeInscriptionController,
                  'Code fourni par XamXam Livraison',
                  Icons.phone,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _inscrire,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.person_add, color: Colors.white),
                    label: Text(
                      _loading ? 'Valider...' : "Valider",
                      style: TextStyle(
                        color: Colors.white, // 👈 écriture blanche
                        fontSize: 14,
                        //fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
