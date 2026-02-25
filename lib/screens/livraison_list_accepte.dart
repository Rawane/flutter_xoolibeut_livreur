import 'package:flutter/material.dart';
import 'package:xoolibeut_livreur/widgets/livraison_list_generic.dart';
import '../services/livraison_service.dart';

class LivraisonsAccepteesPage extends StatelessWidget {
  final LivraisonService livraisonService;
  final String token;

  const LivraisonsAccepteesPage({
    super.key,
    required this.livraisonService,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return LivraisonListGenericPage(
      title: "Mes livraisons acceptées",
      token: token,
      livraisonService: livraisonService,
      // wrapper pour adapter la signature
      fetchLivraisons: (numero, token, page, size) {
        return livraisonService.getDemandesLivraisonPageAccepte(
          numero,
          token,
          page: page,
          size: size,
        );
      },
      emptyMessage: "Aucune livraison acceptée",
    );
  }
}
