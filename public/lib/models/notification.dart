class NotificationModel {
  final int id;
  final String titre;
  final String contenu;
  final String type;
  final bool estLu;
  final DateTime dateEnvoi;

  // Logement details
  final int? logementId;
  final String? logementTitre;
  final String? logementDescription;
  final String? logementAdresse;
  final String? logementVille;
  final double? logementLoyer;
  final double? logementSuperficie;
  final int? logementNombrePieces;
  final bool? logementMeuble;
  final String? logementPhotos;

  // Owner details
  final int? ownerId;
  final String? ownerNom;
  final String? ownerPrenom;
  final String? ownerEmail;
  final String? ownerTelephone;
  final String? ownerPhoto;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.type,
    required this.estLu,
    required this.dateEnvoi,
    this.logementId,
    this.logementTitre,
    this.logementDescription,
    this.logementAdresse,
    this.logementVille,
    this.logementLoyer,
    this.logementSuperficie,
    this.logementNombrePieces,
    this.logementMeuble,
    this.logementPhotos,
    this.ownerId,
    this.ownerNom,
    this.ownerPrenom,
    this.ownerEmail,
    this.ownerTelephone,
    this.ownerPhoto,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      titre: json['titre'],
      contenu: json['contenu'] ?? '',
      type: json['type'],
      estLu: json['est_lu'] ?? false,
      dateEnvoi: DateTime.parse(json['date_envoi']),
      logementId: json['logement_id'],
      logementTitre: json['logement_titre'],
      logementDescription: json['logement_description'],
      logementAdresse: json['logement_adresse'],
      logementVille: json['logement_ville'],
      logementLoyer:
          (json['logement_loyer'] != null)
              ? double.tryParse(json['logement_loyer'].toString())
              : null,
      logementSuperficie:
          (json['logement_superficie'] != null)
              ? double.tryParse(json['logement_superficie'].toString())
              : null,
      logementNombrePieces: json['logement_nombre_pieces'],
      logementMeuble: json['logement_meuble'],
      logementPhotos: json['logement_photos'],
      ownerId: json['owner_id'],
      ownerNom: json['owner_nom'],
      ownerPrenom: json['owner_prenom'],
      ownerEmail: json['owner_email'],
      ownerTelephone: json['owner_telephone'],
      ownerPhoto: json['owner_photo'],
    );
  }
}
