import 'package:flutter/material.dart';
import 'package:xoolibeut_livreur/widgets/livraison_list_generic.dart';
import '../services/livraison_service.dart';

class LivraisonsLivrePage extends StatelessWidget {
  final LivraisonService livraisonService;
  final String token;
  const LivraisonsLivrePage({
    super.key,
    required this.livraisonService,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return LivraisonListGenericPage(
      title: "Mes livraisons effectuées",
      token: token,
      livraisonService: livraisonService,
      // wrapper pour adapter la signature
      fetchLivraisons: (numero, token, page, size) {
        return livraisonService.getDemandesLivraisonPageLivre(
          numero,
          token,
          page: page,
          size: size,
        );
      },
      emptyMessage: "Aucune livraison effectuée",
    );
  }
}
