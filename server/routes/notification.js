const express = require('express');
const router = express.Router();
const db = require('../config');

// Get notifications for a user, including logement and owner info if relevant
router.get('/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    // Fetch notifications with logement and owner info if the notification is about a logement (e.g., candidature)
    const notifications = await db.query(`
      SELECT 
        n.id, n.titre, n.contenu, n.type, n.est_lu, n.date_envoi,
        l.id AS logement_id, l.titre AS logement_titre, l.description AS logement_description, l.adresse AS logement_adresse, l.ville AS logement_ville, l.loyer AS logement_loyer, l.superficie AS logement_superficie, l.nombre_pieces AS logement_nombre_pieces, l.meuble AS logement_meuble,
        (
          SELECT COALESCE(string_agg(pl.url, ','), '')
          FROM photos_logement pl
          WHERE pl.logement_id = l.id
        ) AS logement_photos,
        u.id AS owner_id, u.nom AS owner_nom, u.prenom AS owner_prenom, u.email AS owner_email, u.telephone AS owner_telephone, u.photo_profil AS owner_photo
      FROM notifications n
      LEFT JOIN logements l ON n.logement_id = l.id
      LEFT JOIN users u ON l.proprietaire_id = u.id
      WHERE n.utilisateur_id = $1
      ORDER BY n.date_envoi DESC
    `, [userId]);
    res.json(notifications.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des notifications.' });
  }
});

// Get all accepted colocations for a user (with logement and owner details)
router.get('/accepted-colocations/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const result = await db.query(`
      SELECT 
        col.id AS colocation_id,
        col.description AS colocation_description,
        col.date_creation AS colocation_date_creation,
        l.id AS logement_id, l.titre AS logement_titre, l.description AS logement_description, l.adresse AS logement_adresse, l.ville AS logement_ville, l.loyer AS logement_loyer, l.superficie AS logement_superficie, l.nombre_pieces AS logement_nombre_pieces, l.meuble AS logement_meuble,
        (
          SELECT COALESCE(string_agg(pl.url, ','), '')
          FROM photos_logement pl
          WHERE pl.logement_id = l.id
        ) AS logement_photos,
        u.id AS owner_id, u.nom AS owner_nom, u.prenom AS owner_prenom, u.email AS owner_email, u.telephone AS owner_telephone, u.photo_profil AS owner_photo
      FROM colocataires c
      JOIN colocations col ON c.colocation_id = col.id
      JOIN logements l ON col.logement_id = l.id
      JOIN users u ON l.proprietaire_id = u.id
      WHERE c.utilisateur_id = $1
        AND (c.date_sortie IS NULL OR c.date_sortie > CURRENT_DATE)
      ORDER BY col.date_creation DESC
    `, [userId]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des colocations acceptées.' });
  }
});

// Create a notification (to be called when a candidature is accepted)
router.post('/', async (req, res) => {
  const { titre, contenu, type, utilisateur_id } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO notifications (titre, contenu, type, utilisateur_id) VALUES ($1, $2, $3, $4) RETURNING *`,
      [titre, contenu, type, utilisateur_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de la notification.' });
  }
});

module.exports = router;
