class AcceptedColocation {
  final int colocationId;
  final String colocationDescription;
  final String? colocationDateCreation;
  final int logementId;
  final String logementTitre;
  final String logementDescription;
  final String logementAdresse;
  final String logementVille;
  final double logementLoyer;
  final double? logementSuperficie;
  final int? logementNombrePieces;
  final bool logementMeuble;
  final String? logementPhotos;
  final int ownerId;
  final String ownerNom;
  final String ownerPrenom;
  final String ownerEmail;
  final String ownerTelephone;
  final String? ownerPhoto;

  AcceptedColocation({
    required this.colocationId,
    required this.colocationDescription,
    this.colocationDateCreation,
    required this.logementId,
    required this.logementTitre,
    required this.logementDescription,
    required this.logementAdresse,
    required this.logementVille,
    required this.logementLoyer,
    this.logementSuperficie,
    this.logementNombrePieces,
    required this.logementMeuble,
    this.logementPhotos,
    required this.ownerId,
    required this.ownerNom,
    required this.ownerPrenom,
    required this.ownerEmail,
    required this.ownerTelephone,
    this.ownerPhoto,
  });

  factory AcceptedColocation.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    return AcceptedColocation(
      colocationId: json['colocation_id'],
      colocationDescription: json['colocation_description'] ?? '',
      colocationDateCreation: json['colocation_date_creation'],
      logementId: json['logement_id'],
      logementTitre: json['logement_titre'] ?? '',
      logementDescription: json['logement_description'] ?? '',
      logementAdresse: json['logement_adresse'] ?? '',
      logementVille: json['logement_ville'] ?? '',
      logementLoyer: parseDouble(json['logement_loyer']),
      logementSuperficie: json['logement_superficie'] != null
          ? parseDouble(json['logement_superficie'])
          : null,
      logementNombrePieces: parseInt(json['logement_nombre_pieces']),
      logementMeuble: json['logement_meuble'] is bool
          ? json['logement_meuble']
          : (json['logement_meuble']?.toString().toLowerCase() == 'true'),
      logementPhotos: json['logement_photos'],
      ownerId: json['owner_id'],
      ownerNom: json['owner_nom'] ?? '',
      ownerPrenom: json['owner_prenom'] ?? '',
      ownerEmail: json['owner_email'] ?? '',
      ownerTelephone: json['owner_telephone']?.toString() ?? '',
      ownerPhoto: json['owner_photo'],
    );
  }
}
