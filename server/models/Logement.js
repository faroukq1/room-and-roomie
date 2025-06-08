// models/Logement.js
const pool = require("../config");

class Logement {
  // Get all images for a logement
  static async getImagesByLogementId(logementId) {
    try {
      const result = await pool.query(
        'SELECT url FROM photos_logement WHERE logement_id = $1',
        [logementId]
      );
      // Return array of URLs (as strings)
      return result.rows.map(row => row.url);
    } catch (error) {
      console.error('Erreur lors de la récupération des images du logement:', error);
      return [];
    }
  }
  // Create a new logement (property)
  static async createLogement({
    proprietaire_id,
    titre,
    description,
    loyer,
    adresse,
    ville,
    type_logement,
    disponible_a_partir,
    code_postal = null,
    superficie = null,
    nombre_pieces = null,
    nombre_coloc_max = null,
    charges_incluses = false,
    meuble = false,
    est_actif = true,
  }) {
    try {
      const result = await pool.query(
        `INSERT INTO logements 
        (proprietaire_id, titre, description, loyer, adresse, ville, type_logement, disponible_a_partir, 
         code_postal, superficie, nombre_pieces, nombre_coloc_max, charges_incluses, meuble, est_actif) 
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15) 
        RETURNING *`,
        [
          proprietaire_id,
          titre,
          description,
          loyer,
          adresse,
          ville,
          type_logement,
          disponible_a_partir,
          code_postal,
          superficie,
          nombre_pieces,
          nombre_coloc_max,
          charges_incluses,
          meuble,
          est_actif,
        ]
      );
      return result.rows[0];
    } catch (error) {
      console.error("❌ Erreur lors de la création du logement :", error);
      throw new Error("Erreur lors de l'ajout du logement");
    }
  }

  // Get all logements
  static async getLogements() {
    try {
      const result = await pool.query("SELECT * FROM logements ORDER BY date_creation DESC");
      return result.rows;
    } catch (error) {
      console.error("❌ Erreur lors de la récupération des logements :", error);
      throw new Error("Erreur lors de la récupération des logements");
    }
  }

  // Get a logement by ID
  static async getLogementById(id) {
    try {
      const result = await pool.query("SELECT * FROM logements WHERE id = $1", [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error("❌ Erreur lors de la récupération du logement :", error);
      throw new Error("Erreur lors de la récupération du logement");
    }
  }

  // Update a logement
  static async updateLogement(
    id,
    {
      titre,
      description,
      loyer,
      adresse,
      ville,
      type_logement,
      disponible_a_partir,
      code_postal,
      superficie,
      nombre_pieces,
      nombre_coloc_max,
      charges_incluses,
      meuble,
      est_actif,
    }
  ) {
    try {
      const result = await pool.query(
        `UPDATE logements 
        SET titre = $1, description = $2, loyer = $3, adresse = $4, ville = $5, type_logement = $6, 
            disponible_a_partir = $7, code_postal = $8, superficie = $9, nombre_pieces = $10, 
            nombre_coloc_max = $11, charges_incluses = $12, meuble = $13, est_actif = $14
        WHERE id = $15 
        RETURNING *`,
        [
          titre,
          description,
          loyer,
          adresse,
          ville,
          type_logement,
          disponible_a_partir,
          code_postal,
          superficie,
          nombre_pieces,
          nombre_coloc_max,
          charges_incluses,
          meuble,
          est_actif,
          id,
        ]
      );
      return result.rows[0];
    } catch (error) {
      console.error("❌ Erreur lors de la mise à jour du logement :", error);
      throw new Error("Erreur lors de la mise à jour du logement");
    }
  }

  // Delete a logement
  static async deleteLogement(id) {
    try {
      await pool.query("DELETE FROM logements WHERE id = $1", [id]);
      return { message: "Logement supprimé avec succès" };
    } catch (error) {
      console.error("❌ Erreur lors de la suppression du logement :", error);
      throw new Error("Erreur lors de la suppression du logement");
    }
  }

  // Search logements with filters
  static async searchLogements({ ville, loyer_min, loyer_max, type_logement }) {
    try {
      let query = "SELECT * FROM logements WHERE 1=1";
      const values = [];
      let paramIndex = 1;

      if (ville) {
        query += ` AND ville = $${paramIndex++}`;
        values.push(ville);
      }
      if (loyer_min !== undefined && !isNaN(parseFloat(loyer_min))) {
        query += ` AND loyer >= $${paramIndex++}`;
        values.push(parseFloat(loyer_min));
      }
      if (loyer_max !== undefined && !isNaN(parseFloat(loyer_max))) {
        query += ` AND loyer <= $${paramIndex++}`;
        values.push(parseFloat(loyer_max));
      }
      if (type_logement) {
        query += ` AND type_logement = $${paramIndex++}`;
        values.push(type_logement);
      }

      query += " ORDER BY date_creation DESC";

      const result = await pool.query(query, values);
      return result.rows;
    } catch (error) {
      console.error("❌ Erreur lors de la recherche des logements :", error);
      throw new Error("Erreur lors de la recherche des logements");
    }
  }
}

module.exports = Logement;