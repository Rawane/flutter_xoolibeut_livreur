import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/livraison_service.dart';
import '../providers/livreur_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/livraison_card.dart';
import '../models/livraison.dart';

class LivraisonListGenericPage extends StatefulWidget {
  final LivraisonService livraisonService;
  final String token;
  final String title;
  final String emptyMessage;
  final Future<List<LivraisonLivreur>> Function(
    String numero,
    String token,
    int page,
    int size,
  )
  fetchLivraisons;

  const LivraisonListGenericPage({
    super.key,
    required this.livraisonService,
    required this.token,
    required this.title,
    required this.fetchLivraisons,
    required this.emptyMessage, //
  });

  @override
  State<LivraisonListGenericPage> createState() =>
      _LivraisonListGenericPageState();
}

class _LivraisonListGenericPageState extends State<LivraisonListGenericPage> {
  final List<LivraisonLivreur> _livraisons = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final numeroLivreur = Provider.of<LivreurProvider>(
      context,
      listen: false,
    ).numeroLivreur;
    if (numeroLivreur == null) return;

    try {
      final newLivraisons = await widget.fetchLivraisons(
        numeroLivreur,
        widget.token,
        _currentPage,
        _pageSize,
      );
      setState(() {
        _livraisons.addAll(newLivraisons);
        _currentPage++;
        if (newLivraisons.length < _pageSize) _hasMore = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numeroLivreur = Provider.of<LivreurProvider>(context).numeroLivreur;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        numeroLivreur: numeroLivreur ?? '',
        onBack: () => Navigator.pop(context),
      ),
      body: numeroLivreur == null
          ? const Center(child: Text("Numéro livreur introuvable"))
          : _livraisons.isEmpty && !_isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    widget.emptyMessage,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _livraisons.length + 1,
              itemBuilder: (context, index) {
                if (index == _livraisons.length) {
                  return _hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }

                final livraison = _livraisons[index];

                return LivraisonCard(
                  livraison: livraison,
                  onActionPressed: livraison.statusLivraison == 'ACCEPTE'
                      ? () => _envoieEnRoute(livraison)
                      : livraison.statusLivraison == 'DEMANDE'
                      ? () => _accepterLivraison(livraison, index)
                      : null,
                  onActionPressedColis: livraison.statusLivraison == 'ACCEPTE'
                      ? () => _colisPrisParLivreur(livraison)
                      : null,
                  onActionPressedAnnulerColis:
                      livraison.statusLivraison == 'ACCEPTE'
                      ? () => _annulerLivraison(livraison, index)
                      : null,
                );
              },
            ),
    );
  }

  Future<void> _envoieEnRoute(LivraisonLivreur livraison) async {
    try {
      final numeroLivreur = Provider.of<LivreurProvider>(
        context,
        listen: false,
      ).numeroLivreur;

      if (numeroLivreur == null) {
        throw "Numéro livreur introuvable";
      }

      await widget.livraisonService.notificationEnroute(
        numeroLivreur,
        livraison.numero,
        widget.token,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Notification envoyée ✔")));

      // 🔥 NE RIEN RAFRAÎCHIR
      // Aucune modification de la liste
      // Pas de setState global
      // Pas de reload des pages
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  Future<void> _refreshLivraisons() async {
    setState(() {
      _livraisons.clear();
      _currentPage = 0;
      _hasMore = true;
    });

    await _loadMore();
  }

  Future<void> _colisPrisParLivreur(LivraisonLivreur livraison) async {
    try {
      final numeroLivreur = Provider.of<LivreurProvider>(
        context,
        listen: false,
      ).numeroLivreur;

      if (numeroLivreur == null) {
        throw "Numéro livreur introuvable";
      }

      await widget.livraisonService.changeStatusLivraison(
        numeroLivreur,
        livraison.numero,
        'PRIS_PAR_LIVREUR',
        widget.token,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Notification envoyée ✔")));

      await _refreshLivraisons();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  Future<void> _accepterLivraison(LivraisonLivreur livraison, int index) async {
    try {
      final numeroLivreur = Provider.of<LivreurProvider>(
        context,
        listen: false,
      ).numeroLivreur;

      if (numeroLivreur == null) {
        throw "Numéro livreur introuvable";
      }

      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirmation"),
          content: const Text(
            "Voulez-vous accepter cette demande de livraison ?",
          ),
          actions: [
            TextButton(
              child: const Text("Non"),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            TextButton(
              child: const Text("Oui"),
              onPressed: () async {
                Navigator.pop(ctx); // 🔴 fermer le dialog
                try {
                  final livraisonAcceptee = await widget.livraisonService
                      .accepterLivraison(
                        numeroLivreur,
                        livraison.numero,
                        widget.token,
                      );

                  if (!mounted) return;

                  setState(() {
                    _livraisons.removeAt(index);
                    _livraisons.insert(0, livraisonAcceptee);
                  });
                  Navigator.pushNamed(context, '/livraisonsAcceptees');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Livraison acceptée ✔")),
                  );
                } catch (e) {
                  if (!mounted) return;
                  String message;
                  if (e.toString().contains("DEJA_ACCEPTEE")) {
                    message =
                        "Cette commande a déjà été acceptée par un autre livreur ❌";
                  } else {
                    message = "Une erreur est survenue. Veuillez réessayer.";
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  Future<void> _annulerLivraison(LivraisonLivreur livraison, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Confirmation"),
          content: const Text(
            "Voulez-vous vraiment annuler cette livraison ?\n\n"
            "Elle sera remise en attribution.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Non"),
            ),
            ElevatedButton(
              // style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 54, 244, 212)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Oui, annuler"),
            ),
          ],
        );
      },
    );

    // 👇 Si l'utilisateur annule ou ferme la boîte
    if (confirm != true) return;

    final numeroLivreur = Provider.of<LivreurProvider>(
      context,
      listen: false,
    ).numeroLivreur;

    if (numeroLivreur == null) return;

    try {
      await widget.livraisonService.annulerLivraison(
        numeroLivreur,
        livraison.numero,
        widget.token,
      );

      setState(() {
        _livraisons.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Livraison remise en attribution ✔")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }
}
