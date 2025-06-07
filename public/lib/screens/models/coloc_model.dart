import 'dart:convert';

class ColocModel {
  final int userId;
  final String nom;
  final String prenom;
  final String photoProfil;
  final String userVille;
  final String sexe;
  final DateTime? dateEntree;
  final DateTime? dateSortie;
  final int logementId;
  final String logementTitre;
  final String logementVille;
  final double loyer;
  final String typeLogement;
  final DateTime disponibleAPartir;
  final double superficie;
  final int nombrePieces;
  final bool meuble;
  final int colocationId;

  ColocModel({
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.photoProfil,
    required this.userVille,
    required this.sexe,
    this.dateEntree,
    this.dateSortie,
    required this.logementId,
    required this.logementTitre,
    required this.logementVille,
    required this.loyer,
    required this.typeLogement,
    required this.disponibleAPartir,
    required this.superficie,
    required this.nombrePieces,
    required this.meuble,
    required this.colocationId,
  });

  factory ColocModel.fromJson(Map<String, dynamic> json) {
    return ColocModel(
      userId: json['user_id'] ?? 0,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      photoProfil: json['photo_profil'] ?? '',
      userVille: json['user_ville'] ?? '',
      sexe: json['sexe'] ?? '',
      dateEntree: json['date_entree'] != null
          ? DateTime.parse(json['date_entree'])
          : null,
      dateSortie: json['date_sortie'] != null
          ? DateTime.parse(json['date_sortie'])
          : null,
      logementId: json['logement_id'] ?? 0,
      logementTitre: json['logement_titre'] ?? '',
      logementVille: json['logement_ville'] ?? '',
      loyer: double.parse((json['loyer'] ?? '0').toString()),
      typeLogement: json['type_logement'] ?? '',
      disponibleAPartir: DateTime.parse(
        json['disponible_a_partir'] ?? DateTime.now().toIso8601String(),
      ),
      superficie: double.parse((json['superficie'] ?? '0').toString()),
      nombrePieces: json['nombre_pieces'] ?? 0,
      meuble: json['meuble'] ?? false,
      colocationId: json['colocation_id'] ?? 0,
    );
  }
}
