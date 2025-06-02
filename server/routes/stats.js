const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();
const pool = require("../config");


// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1]; // Expecting 'Bearer <token>'
  if (!token) {
    return res.status(401).json({ message: 'No token provided' });
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET); // Replace with your JWT secret
    req.userId = decoded.userId; // Store decoded userId for potential use
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};

// GET /api/user/:id/stats
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    if (isNaN(userId)) return res.status(400).json({ message: 'Invalid user ID' });
    
    // SQL queries for stats
    const propertiesQuery = 'SELECT COUNT(*) AS properties FROM logements WHERE proprietaire_id = $1';
    const favoritesQuery = 'SELECT COUNT(*) AS favorites FROM favoris WHERE locataire_id = $1';
    const viewsQuery = 'SELECT COUNT(*) AS views FROM candidatures c JOIN logements l ON c.logement_id = l.id WHERE l.proprietaire_id = $1';
    const userQuery = 'SELECT nom, email, photo_profil AS avatar_url FROM users WHERE id = $1';

    // Execute queries concurrently
    const [propertiesRes, favoritesRes, viewsRes, userRes] = await Promise.all([
      pool.query(propertiesQuery, [userId]),
      pool.query(favoritesQuery, [userId]),
      pool.query(viewsQuery, [userId]),
      pool.query(userQuery, [userId]),
    ]);

    // Check if user exists
    if (userRes.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Prepare response
    const response = {
      properties: parseInt(propertiesRes.rows[0].properties) || 0,
      favorites: parseInt(favoritesRes.rows[0].favorites) || 0,
      views: parseInt(viewsRes.rows[0].views) || 0,
      name: userRes.rows[0].nom || null,
      email: userRes.rows[0].email || null,
      avatar_url: userRes.rows[0].avatar_url || null,
    };

    res.status(200).json(response);
  } catch (error) {
    console.error('Error fetching user stats:', error);
    res.status(500).json({ message: 'Error fetching user stats', error: error.message });
  }
});

module.exports = router;