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
    } on LivreurSuspenduException {
      if (!mounted) return;
      setState(() {
        _isSuspendu = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final numeroLivreur = Provider.of<LivreurProvider>(
      context,
    ).numeroLivreur; // 👉 Déclenchement du dialog après rendu

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        numeroLivreur: numeroLivreur ?? '',
        onBack: () => Navigator.pop(context),
      ),
      body: numeroLivreur == null
          ? const Center(child: Text("Numéro livreur introuvable"))
          // ✅ CAS 403 → écran bloqué
          : _isSuspendu
          ? _buildSuspenduState()
          // ✅ CAS liste vide normale
          : _livraisons.isEmpty && !_isLoading
          ? _buildEmptyState()
          // ✅ CAS liste normale
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
              "Votre compte est suspendu temporairement.\n"
              "Veuillez contacter le support.",
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
    } on LivreurSuspenduException {
      if (!mounted) return;
      setState(() => _isSuspendu = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
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
    } on LivreurSuspenduException {
      if (!mounted) return;
      setState(() => _isSuspendu = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
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

      setState(() {
        _livraisons.removeAt(index);
        _livraisons.insert(0, livraisonAcceptee);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Livraison acceptée ✔")));
    } on LivreurSuspenduException {
      if (!mounted) return;
      setState(() => _isSuspendu = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  Future<void> _annulerLivraison(LivraisonLivreur livraison, int index) async {
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

      setState(() {
        _livraisons.removeAt(index);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Livraison annulée ✔")));
    } on LivreurSuspenduException {
      if (!mounted) return;
      setState(() => _isSuspendu = true);
    } catch (e) {
      if (!mounted) return;
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
}
