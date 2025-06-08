const express = require('express');
const router = express.Router();
const db = require('../config');

// POST /api/paiements - create a new payment
router.post('/', async (req, res) => {
  const { montant, moyen_paiement, locataire_id, logement_id } = req.body;
  if (!montant || !moyen_paiement || !locataire_id || !logement_id) {
    return res.status(400).json({ error: 'Missing required fields.' });
  }
  console.log(montant, moyen_paiement, locataire_id, logement_id);
  try {
    const result = await db.query(
      `INSERT INTO paiements (montant, moyen_paiement, locataire_id, logement_id) \
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [montant, moyen_paiement, locataire_id, logement_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.log(err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/paiements/proprietaire/:proprietaireId - get all payments for a proprietor's properties
router.get('/proprietaire/:proprietaireId', async (req, res) => {
  const { proprietaireId } = req.params;
  try {
    const result = await db.query(
      `SELECT 
        paiements.*, 
        users.nom, users.prenom, users.email, 
        logements.titre 
      FROM paiements
      JOIN users ON paiements.locataire_id = users.id
      JOIN logements ON paiements.logement_id = logements.id
      WHERE logements.proprietaire_id = $1
      ORDER BY paiements.date_paiement DESC`,
      [proprietaireId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
