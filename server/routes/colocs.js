const express = require('express');
const router = express.Router();
const pool = require('../config');
const jwt = require('jsonwebtoken');

// Middleware to authenticate JWT
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers.authorization;
    const token = authHeader?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token provided' });
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.userId = decoded.userId;
        next();
    } catch (err) {
        res.status(401).json({ message: 'Invalid token' });
    }
};

// Get all colocataires with pagination
router.get('/', authenticateToken, async (req, res) => {
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

// Get details of a specific colocation
router.get('/colocation/:id', authenticateToken, async (req, res) => {
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