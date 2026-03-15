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
    required this.emptyMessage,
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
  bool _isSuspendu = false;

  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMore();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          !_isSuspendu &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  /// 🔹 Centralisation de la gestion des erreurs UI (Internet, Timeout, Métier)
  void _handleUIError(dynamic e) {
    if (!mounted) return;

    if (e is LivreurSuspenduException) {
      setState(() => _isSuspendu = true);
      return;
    }

    String message;
    if (e is NoInternetException) {
      message = "🌐 Pas de connexion internet. Vérifiez votre réseau.";
    } else if (e is RequestTimeoutException) {
      message = "⏳ Le serveur met trop de temps à répondre.";
    } else {
      message = "Erreur technique ";
    }

    // Gestion des cas métiers spécifiques contenus dans le message
    if (message.contains("TROP_LOIN")) {
      final distanceLabel = message.split(":").last;
      _showDistanceErrorDialog(distanceLabel);
    } else if (message.contains("DEJA_ACCEPTEE")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Désolé, cette course a déjà été prise.")),
      );
      _refreshLivraisons();
    } else {
      // Erreur générale ou réseau
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "RÉESSAYER",
            textColor: Colors.white,
            onPressed: () => _loadMore(),
          ),
        ),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isSuspendu) return;

    setState(() => _isLoading = true);

    final numeroLivreur = Provider.of<LivreurProvider>(
      context,
      listen: false,
    ).numeroLivreur;

    if (numeroLivreur == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final newLivraisons = await widget.fetchLivraisons(
        numeroLivreur,
        widget.token,
        _currentPage,
        _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _livraisons.addAll(newLivraisons);
        _currentPage++;
        if (newLivraisons.length < _pageSize) _hasMore = false;
      });
    } catch (e) {
      _handleUIError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          : _isSuspendu
          ? _buildSuspenduState()
          : _livraisons.isEmpty && !_isLoading
          ? RefreshIndicator(
              onRefresh: _refreshLivraisons,
              child: Stack(children: [ListView(), _buildEmptyState()]),
            )
          : RefreshIndicator(
              onRefresh: _refreshLivraisons,
              child: ListView.builder(
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
            ),
    );
  }

  Widget _buildSuspenduState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.block, size: 90, color: Colors.redAccent),
            SizedBox(height: 20),
            Text(
              "Compte suspendu",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Votre compte est suspendu temporairement.\nVeuillez contacter le support.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _envoieEnRoute(LivraisonLivreur livraison) async {
    try {
      final numeroLivreur = Provider.of<LivreurProvider>(
        context,
        listen: false,
      ).numeroLivreur;
      if (numeroLivreur == null) return;

      await widget.livraisonService.notificationEnroute(
        numeroLivreur,
        livraison.numero,
        widget.token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Notification envoyée ✔")));
    } catch (e) {
      _handleUIError(e);
    }
  }

  Future<void> _colisPrisParLivreur(LivraisonLivreur livraison) async {
    try {
      final numeroLivreur = Provider.of<LivreurProvider>(
        context,
        listen: false,
      ).numeroLivreur;
      if (numeroLivreur == null) return;

      await widget.livraisonService.changeStatusLivraison(
        numeroLivreur,
        livraison.numero,
        'PRIS_PAR_LIVREUR',
        widget.token,
      );
      await _refreshLivraisons();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Statut mis à jour ✔")));
    } catch (e) {
      _handleUIError(e);
    }
  }

  Future<void> _accepterLivraison(LivraisonLivreur livraison, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text(
          "Voulez-vous accepter cette demande de livraison ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Oui"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final numeroLivreur = Provider.of<LivreurProvider>(
        context,
        listen: false,
      ).numeroLivreur;
      if (numeroLivreur == null) return;

      final livraisonAcceptee = await widget.livraisonService.accepterLivraison(
        numeroLivreur,
        livraison.numero,
        widget.token,
      );

      if (!mounted) return;

      /*setState(() {
        _livraisons.removeAt(index);
        _livraisons.insert(0, livraisonAcceptee);
      });*/
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Livraison acceptée ✔"),
          backgroundColor: Color(0xFF00353F), // Même bleu que votre bandeau
          duration: Duration(
            seconds: 2,
          ), // Un peu plus court pour être plus dynamique
        ),
      );
      Navigator.pushReplacementNamed(context, '/livraisonsAcceptees');
    } catch (e) {
      _handleUIError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDistanceErrorDialog(String distance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 10),
            Text("Zone trop éloignée"),
          ],
        ),
        content: Text(
          "Vous êtes actuellement à $distance du point de départ. Vous devez vous rapprocher pour accepter cette demande.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("COMPRIS"),
          ),
        ],
      ),
    );
  }

  Future<void> _annulerLivraison(LivraisonLivreur livraison, int index) async {
    // 1. Afficher le dialogue de confirmation
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Confirmer l'annulation"),
        content: Text(
          "Voulez-vous vraiment annuler la livraison n° ${livraison.numero} ?",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Retourne false
            child: const Text("RETOUR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Retourne true
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("OUI, ANNULER"),
          ),
        ],
      ),
    );

    // 2. Si l'utilisateur a annulé le dialogue ou cliqué sur RETOUR, on arrête là
    if (confirm != true) return;

    // 3. Procéder à l'annulation technique
    try {
      final numeroLivreur = Provider.of<LivreurProvider>(
        context,
        listen: false,
      ).numeroLivreur;
      if (numeroLivreur == null) return;

      await widget.livraisonService.annulerLivraison(
        numeroLivreur,
        livraison.numero,
        widget.token,
      );

      if (!mounted) return;
      setState(() => _livraisons.removeAt(index));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Livraison annulée ✔"),
          backgroundColor: Colors.orange, // Couleur d'avertissement
        ),
      );
    } catch (e) {
      _handleUIError(e);
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
