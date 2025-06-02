const pool = require("../config");

class Annonce {
  // Méthode pour créer une annonce
  static async createAnnonce(proprietaire_id, titre, description, prix, adresse, ville, type_logement, disponibilite) {
    try {
      const result = await pool.query(
        `INSERT INTO annonces 
        (proprietaire_id, titre, description, prix, adresse, ville, type_logement, disponibilite) 
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
        RETURNING *`,
        [proprietaire_id, titre, description, prix, adresse, ville, type_logement, disponibilite]
      );
      return result.rows[0];
    } catch (error) {
      console.error("❌ Erreur lors de la création de l'annonce :", error);
      throw new Error("Erreur lors de l'ajout de l'annonce");
    }
  }

  // Méthode pour récupérer toutes les annonces
  static async getAnnonces() {
    const result = await pool.query("SELECT * FROM annonces ORDER BY date_creation DESC");
    return result.rows;
  }

  // Méthode pour récupérer une annonce par ID
  static async getAnnonceById(id) {
    const result = await pool.query("SELECT * FROM annonces WHERE id = $1", [id]);
    return result.rows[0] || null;
  }

  // Méthode pour mettre à jour une annonce
  static async updateAnnonce(id, titre, description, prix, adresse, ville, type_logement, disponibilite) {
    try {
      const result = await pool.query(
        `UPDATE annonces 
        SET titre = $1, description = $2, prix = $3, adresse = $4, ville = $5, type_logement = $6, disponibilite = $7
        WHERE id = $8 
        RETURNING *`,
        [titre, description, prix, adresse, ville, type_logement, disponibilite, id]
      );
      return result.rows[0];
    } catch (error) {
      console.error("❌ Erreur lors de la mise à jour :", error);
      throw new Error("Erreur lors de la mise à jour de l'annonce");
    }
  }

  // Méthode pour supprimer une annonce
  static async deleteAnnonce(id) {
    await pool.query("DELETE FROM annonces WHERE id = $1", [id]);
  }

  // Méthode pour rechercher des annonces avec des filtres
  static async searchAnnonces(ville, prix_min, prix_max, type_logement) {
    let query = "SELECT * FROM annonces WHERE 1=1"; // `1=1` pour que ça fonctionne même sans filtres

    // Convertir les prix en nombres
    if (prix_min) prix_min = parseFloat(prix_min);
    if (prix_max) prix_max = parseFloat(prix_max);

    // Ajout des conditions selon les filtres
    if (ville) query += ` AND ville = '${ville}'`;
    if (!isNaN(prix_min)) query += ` AND prix >= ${prix_min}`;  // On vérifie que prix_min est un nombre
    if (!isNaN(prix_max)) query += ` AND prix <= ${prix_max}`;  // On vérifie que prix_max est un nombre
    if (type_logement) query += ` AND type_logement = '${type_logement}'`;

    try {
      const result = await pool.query(query);  // Exécution de la requête SQL
      return result.rows; // On retourne les résultats
    } catch (error) {
      console.error("Erreur lors de la recherche des annonces :", error);
      throw error;  // Si une erreur se produit, on la lance
    }
  }
}

module.exports = Annonce;
