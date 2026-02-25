import 'package:flutter/material.dart';
import 'package:xoolibeut_livreur/widgets/livraison_list_generic.dart';
import '../services/livraison_service.dart';

class LivraisonsDemandePage extends StatelessWidget {
  final LivraisonService livraisonService;
  final String token;

  const LivraisonsDemandePage({
    super.key,
    required this.livraisonService,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return LivraisonListGenericPage(
      title: "Demande En cours",
      token: token,
      livraisonService: livraisonService,
      // wrapper pour adapter la signature
      fetchLivraisons: (numero, token, page, size) {
        return livraisonService.getDemandesLivraisonPage(
          numero,
          token,
          page: page,
          size: size,
        );
      },
      emptyMessage: "Pas de livraison proche de vous",
    );
  }
}
