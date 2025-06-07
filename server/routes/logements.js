// routes/logements.js
const express = require('express');
const router = express.Router();
const Logement = require('../models/Logement');
const jwt = require('jsonwebtoken');
const pool = require('../config');


// Create a logement
router.post('/create', async (req, res) => {
  try {
    const {
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
    } = req.body;
    const logement = await Logement.createLogement({
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
    });
    res.status(201).json(logement);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Search logements by name
router.get('/search', async (req, res) => {
  try {
    const searchTerm = req.query.name || '';
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    // Get total count of matching logements
    const countQuery = `
      SELECT COUNT(*) 
      FROM logements 
      WHERE est_actif = true 
      AND titre ILIKE '%' || $1 || '%'
    `;
    const totalCount = await pool.query(countQuery, [searchTerm]);
    const total = parseInt(totalCount.rows[0].count);

    // Get paginated search results
    const query = `
      SELECT 
        l.*,
        json_build_object(
          'id', u.id,
          'nom', u.nom,
          'prenom', u.prenom,
          'email', u.email,
          'telephone', u.telephone
        ) as proprietaire
      FROM logements l
      JOIN users u ON l.proprietaire_id = u.id
      WHERE l.est_actif = true
      AND l.titre ILIKE '%' || $1 || '%'
      ORDER BY l.date_creation DESC
      LIMIT $2 OFFSET $3
    `;

    const result = await pool.query(query, [searchTerm, limit, offset]);
    
    res.json({
      logements: result.rows,
      pagination: {
        currentPage: page,
        itemsPerPage: limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get all logements with pagination
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    // Get total count of logements
    const countQuery = 'SELECT COUNT(*) FROM logements WHERE est_actif = true';
    const totalCount = await pool.query(countQuery);
    const total = parseInt(totalCount.rows[0].count);

    // Get paginated logements
    const query = `
      SELECT 
        l.*,
        json_build_object(
          'id', u.id,
          'nom', u.nom,
          'prenom', u.prenom,
          'email', u.email,
          'telephone', u.telephone
        ) as proprietaire
      FROM logements l
      JOIN users u ON l.proprietaire_id = u.id
      WHERE l.est_actif = true
      ORDER BY l.date_creation DESC
      LIMIT $1 OFFSET $2
    `;

    const result = await pool.query(query, [limit, offset]);
    
    res.json({
      logements: result.rows,
      pagination: {
        currentPage: page,
        itemsPerPage: limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
        hasNextPage: offset + limit < total,
        hasPreviousPage: page > 1
      }
    });
  } catch (error) {
    console.error('Error fetching logements:', error);
    res.status(500).json({ message: error.message });
  }
});

// delete logement
router.delete('/:id', async (req, res) => {
  const logementId = parseInt(req.params.id, 10);

  if (isNaN(logementId)) {
    return res.status(400).json({ error: 'ID logement invalide' });
  }

  try {
    // Delete logement by id
    const result = await pool.query('DELETE FROM logements WHERE id = $1 RETURNING *', [logementId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Logement non trouvé' });
    }

    res.json({ message: 'Logement supprimé avec succès', logement: result.rows[0] });
  } catch (error) {
    console.error('Erreur lors de la suppression du logement:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Get filtered logements
router.get('/filter', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    // Build dynamic WHERE clause based on filter parameters
    let whereClause = 'WHERE l.est_actif = true';
    const params = [];
    let paramIndex = 1;

    // Add filters
    // Property type
    if (req.query.propertyType) {
      whereClause += ` AND l.type_logement = $${paramIndex}`;
      params.push(req.query.propertyType);
      paramIndex++;
    }

    // Property sub-type
    if (req.query.propertySubType) {
      whereClause += ` AND l.type_logement = $${paramIndex}`;
      params.push(req.query.propertySubType);
      paramIndex++;
    }

    // Price range
    if (req.query.priceMin) {
      whereClause += ` AND l.loyer >= $${paramIndex}`;
      params.push(parseFloat(req.query.priceMin));
      paramIndex++;
    }

    if (req.query.priceMax) {
      whereClause += ` AND l.loyer <= $${paramIndex}`;
      params.push(parseFloat(req.query.priceMax));
      paramIndex++;
    }

    // Number of bedrooms
    if (req.query.bedrooms) {
      whereClause += ` AND l.nombre_pieces = $${paramIndex}`;
      params.push(parseInt(req.query.bedrooms));
      paramIndex++;
    }

    // Area range
    if (req.query.areaMin) {
      whereClause += ` AND l.superficie >= $${paramIndex}`;
      params.push(parseFloat(req.query.areaMin));
      paramIndex++;
    }

    if (req.query.areaMax) {
      whereClause += ` AND l.superficie <= $${paramIndex}`;
      params.push(parseFloat(req.query.areaMax));
      paramIndex++;
    }

    // Get total count of filtered logements
    const countQuery = `SELECT COUNT(*) FROM logements l ${whereClause}`;
    const totalCount = await pool.query(countQuery, params);
    const total = parseInt(totalCount.rows[0].count);

    // Get filtered logements
    const query = `
      SELECT 
        l.*,
        json_build_object(
          'id', u.id,
          'nom', u.nom,
          'prenom', u.prenom,
          'email', u.email,
          'telephone', u.telephone
        ) as proprietaire
      FROM logements l
      JOIN users u ON l.proprietaire_id = u.id
      ${whereClause}
      ORDER BY l.date_creation DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;
    params.push(limit, offset);

    const result = await pool.query(query, params);
    
    res.json({
      logements: result.rows,
      pagination: {
        currentPage: page,
        itemsPerPage: limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
        hasNextPage: offset + limit < total,
        hasPreviousPage: page > 1
      }
    });
  } catch (error) {
    console.error('Error filtering logements:', error);
    res.status(500).json({ 
      message: 'Error filtering logements', 
      error: error.message 
    });
  }
});

// Get logement by ID
router.get('/:id', async (req, res) => {
  try {
    const logement = await Logement.getLogementById(req.params.id);
    if (!logement) return res.status(404).json({ message: 'Logement not found' });
    res.json(logement);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update logement
router.put('/:id', async (req, res) => {
  try {
    const logement = await Logement.getLogementById(req.params.id);
    if (!logement) return res.status(404).json({ message: 'Logement not found' });
    const updatedLogement = await Logement.updateLogement(req.params.id, req.body);
    res.json(updatedLogement);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Search logements
router.get('/search', async (req, res) => {
  try {
    const { ville, loyer_min, loyer_max, type_logement } = req.query;
    const logements = await Logement.searchLogements({
      ville,
      loyer_min,
      loyer_max,
      type_logement,
    });
    res.json(logements);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Add property to favorites
router.post('/favorites/add', async (req, res) => {
  try {
    const { logementId, userId } = req.body;

    if (!logementId || !userId) {
      return res.status(400).json({ message: 'logementId and userId are required in request body' });
    }

    // Check if already in favorites
    const checkQuery = `
      SELECT * FROM favoris 
      WHERE locataire_id = $1 AND logement_id = $2
    `;
    const existingFavorite = await pool.query(checkQuery, [userId, logementId]);
    
    if (existingFavorite.rows.length > 0) {
      return res.status(400).json({ message: 'Property already in favorites' });
    }

    // Add to favorites
    const query = `
      INSERT INTO favoris (locataire_id, logement_id)
      VALUES ($1, $2)
      RETURNING *
    `;
    const result = await pool.query(query, [userId, logementId]);
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error adding to favorites:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get user's favorite properties
router.get('/favorites/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const query = `
      SELECT 
        l.*,
        f.date_ajout as favoris_date,
        json_build_object(
          'id', u.id,
          'nom', u.nom,
          'prenom', u.prenom,
          'email', u.email,
          'telephone', u.telephone
        ) as proprietaire
      FROM favoris f
      JOIN logements l ON f.logement_id = l.id
      JOIN users u ON l.proprietaire_id = u.id
      WHERE f.locataire_id = $1
      ORDER BY f.date_ajout DESC
    `;
    
    const result = await pool.query(query, [userId]);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching favorites:', error);
    res.status(500).json({ message: error.message });
  }
});

// Remove property from favorites
router.delete('/favorites/:logementId', async (req, res) => {
  try {
    const { logementId } = req.params;
    const userId = req.userId;

    const query = `
      DELETE FROM favoris 
      WHERE locataire_id = $1 AND logement_id = $2
      RETURNING *
    `;
    
    const result = await pool.query(query, [userId, logementId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Favorite not found' });
    }
    
    res.json({ message: 'Property removed from favorites' });
  } catch (error) {
    console.error('Error removing from favorites:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;