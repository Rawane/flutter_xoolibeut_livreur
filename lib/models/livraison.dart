class LivreurDashboard {
  final int jour;
  final int mois;
  final int annee;
  final int total;
  final List<int> livraisonsParMois; // 12 valeurs

  LivreurDashboard({
    required this.jour,
    required this.mois,
    required this.annee,
    required this.total,
    required this.livraisonsParMois,
  });

  factory LivreurDashboard.fromJson(Map<String, dynamic> json) {
    return LivreurDashboard(
      jour: json['nbrLivraisonJour'],
      mois: json['nbrLivraisonMois'],
      annee: json['nbrLivraisonAnnee'],
      total: json['nbrLivraisonTotal'],
      livraisonsParMois: List<int>.from(json['livraisonsParMois']), // backend
    );
  }
}

class LivraisonLivreur {
  final String numero;
  final String? description;
  final String statusLivraison;
  final String? typeLivraison;
  final int livraisonId;
  final String? telephoneLivreur;
  final DateTime? modificationDate;
  final String? libelleStatus;
  final String? lieuDepart;
  final String? lieuArrive;
  final String? distanceAffiche;
  final double? distance;
  final String? nomClient;
  final String? telephoneClient;
  // 🆕 POUR LA MAP
  final double? latitudeRamassage;
  final double? longitudeRamassage;
  final double? latitudeDestinataire;
  final double? longitudeDestinataire;
  final String? telephoneDepart;
  final String? telephoneArrive;
  final String? commentaire;

  LivraisonLivreur({
    required this.numero,
    this.description,
    required this.statusLivraison,
    this.typeLivraison,
    required this.livraisonId,
    this.telephoneLivreur,
    this.modificationDate,
    this.libelleStatus,
    this.lieuDepart,
    this.lieuArrive,
    this.distanceAffiche,
    this.distance,
    this.nomClient,
    this.telephoneClient,
    this.latitudeRamassage,
    this.longitudeRamassage,
    this.latitudeDestinataire,
    this.longitudeDestinataire,
    this.telephoneDepart,
    this.telephoneArrive,
    this.commentaire,
  });

  factory LivraisonLivreur.fromJson(Map<String, dynamic> json) {
    return LivraisonLivreur(
      numero: json['numero'],
      description: json['description'],
      statusLivraison: json['statusLivraison'],
      typeLivraison: json['typeLivraison'],
      livraisonId: json['livraisonId'],
      telephoneLivreur: json['telephoneLivreur'],
      modificationDate: json['modificationDate'] != null
          ? DateTime.parse(json['modificationDate'])
          : null,
      libelleStatus: json['libelleStatus'],
      lieuDepart: json['lieuDepart'],
      lieuArrive: json['lieuArrive'],
      distanceAffiche: json['distanceAffiche'],
      distance: json['distance'],
      nomClient: json['nomClient'],
      telephoneClient: json['telephoneClient'],
      telephoneDepart: json['telephoneDepart'],
      telephoneArrive: json['telephoneArrive'],
      commentaire: json['commentaire'],
      // 🆕 map
      latitudeRamassage: json['latitudeRamassage'] != null
          ? (json['latitudeRamassage'] as num).toDouble()
          : null,
      longitudeRamassage: json['longitudeRamassage'] != null
          ? (json['longitudeRamassage'] as num).toDouble()
          : null,
      latitudeDestinataire: json['latitudeDestinataire'] != null
          ? (json['latitudeDestinataire'] as num).toDouble()
          : null,
      longitudeDestinataire: json['longitudeDestinataire'] != null
          ? (json['longitudeDestinataire'] as num).toDouble()
          : null,
    );
  }
}
