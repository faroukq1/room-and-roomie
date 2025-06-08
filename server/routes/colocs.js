const express = require('express');
const router = express.Router();
const pool = require('../config');
const jwt = require('jsonwebtoken');


// Get all colocataires with pagination
router.get('/', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 5;
        const offset = (page - 1) * limit;

        // Get total count of active colocataires
        const countQuery = `
            SELECT COUNT(DISTINCT c.id)
            FROM colocataires c
            JOIN users u ON c.utilisateur_id = u.id
            JOIN colocations col ON c.colocation_id = col.id
            JOIN logements l ON col.logement_id = l.id
            WHERE c.date_sortie IS NULL OR c.date_sortie > CURRENT_DATE
        `;
        const totalCount = await pool.query(countQuery);
        const total = parseInt(totalCount.rows[0].count);

        // Get paginated colocataires
        const query = `
            SELECT 
                u.id as user_id,
                u.nom,
                u.prenom,
                u.photo_profil,
                u.ville as user_ville,
                u.sexe,
                c.date_entree,
                c.date_sortie,
                l.id as logement_id,
                l.titre as logement_titre,
                l.ville as logement_ville,
                l.loyer,
                l.type_logement,
                l.disponible_a_partir,
                l.superficie,
                l.nombre_pieces,
                l.meuble,
                col.id as colocation_id
            FROM colocataires c
            JOIN users u ON c.utilisateur_id = u.id
            JOIN colocations col ON c.colocation_id = col.id
            JOIN logements l ON col.logement_id = l.id
            WHERE c.date_sortie IS NULL OR c.date_sortie > CURRENT_DATE
            ORDER BY c.date_entree DESC
            LIMIT $1 OFFSET $2
        `;
        
        const result = await pool.query(query, [limit, offset]);
        
        res.json({
            colocataires: result.rows,
            pagination: {
                currentPage: page,
                itemsPerPage: limit,
                totalItems: total,
                totalPages: Math.ceil(total / limit),
                hasNextPage: offset + limit < total,
                hasPreviousPage: page > 1
            }
        });
    } catch (err) {
        console.error('Error fetching colocs:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get colocations and candidatures for a proprietor's properties

// POST /api/colocs/candidature - User applies for colocation
router.post('/candidature', async (req, res) => {
    /*
      Expected body: {
        logement_id: int,
        locataire_id: int, // user id
        message: string (optional)
      }
    */
    const { logement_id, locataire_id, message } = req.body;
    if (!logement_id || !locataire_id) {
        return res.status(400).json({ error: 'logement_id and locataire_id are required' });
    }
    try {
        // Check if already applied and still pending or accepted
        const check = await pool.query(
            `SELECT * FROM candidatures WHERE logement_id = $1 AND locataire_id = $2 AND statut IN ('en_attente', 'acceptee')`,
            [logement_id, locataire_id]
        );
        if (check.rows.length > 0) {
            return res.status(400).json({ error: 'Vous avez déjà postulé ou êtes déjà colocataire.' });
        }
        // Insert candidature
        await pool.query(
            `INSERT INTO candidatures (logement_id, locataire_id, message, statut, date_postulation) VALUES ($1, $2, $3, 'en_attente', CURRENT_DATE)`,
            [logement_id, locataire_id, message || null]
        );
        res.status(201).json({ success: true, message: 'Candidature envoyée avec succès.' });
    } catch (err) {
        console.error('Error applying for colocation:', err);
        res.status(500).json({ error: 'Erreur serveur lors de la candidature.' });
    }
});
router.get('/proprietaire/:proprietaireId', async (req, res) => {
    const { proprietaireId } = req.params;
    try {
        // Current colocations and colocataires
        const colocationsResult = await pool.query(`
            SELECT c.id AS colocation_id, c.description, c.date_creation,
                   l.titre AS logement_titre, l.id AS logement_id,
                   u.id AS colocataire_id, u.nom, u.prenom, u.email,
                   cc.date_entree, cc.date_sortie
            FROM colocations c
            JOIN logements l ON c.logement_id = l.id
            LEFT JOIN colocataires cc ON cc.colocation_id = c.id
            LEFT JOIN users u ON cc.utilisateur_id = u.id
            WHERE l.proprietaire_id = $1
            ORDER BY c.date_creation DESC, cc.date_entree DESC
        `, [proprietaireId]);

        // Pending candidatures
        const candidaturesResult = await pool.query(`
            SELECT can.id AS candidature_id, can.message, can.date_postulation, can.statut,
                   l.titre AS logement_titre, l.id AS logement_id,
                   u.id AS candidat_id, u.nom, u.prenom, u.email
            FROM candidatures can
            JOIN logements l ON can.logement_id = l.id
            JOIN users u ON can.locataire_id = u.id
            WHERE l.proprietaire_id = $1 AND can.statut = 'en_attente'
            ORDER BY can.date_postulation DESC
        `, [proprietaireId]);

        res.json({
            colocations: colocationsResult.rows,
            candidatures: candidaturesResult.rows,
        });
    } catch (err) {
        console.error('Error fetching colocations/candidatures:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Accept or refuse a candidature
router.post('/candidature/:id/action', async (req, res) => {
    const { id } = req.params;
    const { action } = req.body; // 'accept' or 'refuse'
    if (!['accept', 'refuse'].includes(action)) {
        return res.status(400).json({ error: 'Invalid action' });
    }
    try {
        // Get candidature info
        const candResult = await pool.query('SELECT * FROM candidatures WHERE id = $1', [id]);
        if (candResult.rows.length === 0) {
            return res.status(404).json({ error: 'Candidature not found' });
        }
        const candidature = candResult.rows[0];
        if (action === 'accept') {
            // Update statut
            await pool.query("UPDATE candidatures SET statut = 'acceptee' WHERE id = $1", [id]);
            // Add to colocataires if not already present
            const checkColoc = await pool.query('SELECT * FROM colocataires WHERE colocation_id = $1 AND utilisateur_id = $2', [candidature.logement_id, candidature.locataire_id]);
            if (checkColoc.rows.length === 0) {
                // Find colocation for this logement
                const colocResult = await pool.query('SELECT id FROM colocations WHERE logement_id = $1 LIMIT 1', [candidature.logement_id]);
                if (colocResult.rows.length === 0) {
                    return res.status(400).json({ error: 'No colocation found for this property' });
                }
                const colocationId = colocResult.rows[0].id;
                await pool.query('INSERT INTO colocataires (date_entree, colocation_id, utilisateur_id) VALUES (CURRENT_DATE, $1, $2)', [colocationId, candidature.locataire_id]);
            }
            return res.json({ success: true, message: 'Candidature accepted' });
        } else if (action === 'refuse') {
            await pool.query("UPDATE candidatures SET statut = 'refusee' WHERE id = $1", [id]);
            return res.json({ success: true, message: 'Candidature refused' });
        }
    } catch (err) {
        console.error('Error updating candidature:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get details of a specific colocation
router.get('/colocation/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const query = `
            SELECT 
                col.id as colocation_id,
                col.description as colocation_description,
                l.*,
                json_agg(json_build_object(
                    'user_id', u.id,
                    'nom', u.nom,
                    'prenom', u.prenom,
                    'photo_profil', u.photo_profil,
                    'date_entree', c.date_entree,
                    'date_sortie', c.date_sortie
                )) as colocataires
            FROM colocations col
            JOIN logements l ON col.logement_id = l.id
            LEFT JOIN colocataires c ON col.id = c.colocation_id
            LEFT JOIN users u ON c.utilisateur_id = u.id
            WHERE col.id = $1
            GROUP BY col.id, l.id
        `;
        
        const result = await pool.query(query, [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Colocation not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching colocation details:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router; 