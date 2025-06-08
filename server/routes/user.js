const express = require("express");
const multer = require("multer");
const path = require("path");
const os = require("os");
const router = express.Router();
const User = require("../models/User");
const pool = require("../config");

// ➕ Voir profil
router.get("/:id", async (req, res) => {
  try {
    const user = await User.getById(req.params.id);
    if (!user) return res.status(404).json({ message: "Utilisateur non trouvé" });
    res.json(user);
  } catch (error) {
    console.error("Erreur lors de la récupération du profil :", error.message);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

// 📍 Get user's logements with pagination
router.get("/:id/logements", async (req, res) => {
  try {
    const userId = req.params.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    // Get total count of user's logements
    const countQuery = `
      SELECT COUNT(*) 
      FROM logements 
      WHERE proprietaire_id = $1 AND est_actif = true
    `;
    const totalCount = await pool.query(countQuery, [userId]);
    const total = parseInt(totalCount.rows[0].count);

    // Get paginated logements for user
    const query = `
      SELECT 
        l.*,
        (
          SELECT json_agg(
            json_build_object(
              'url', p.url,
              'est_principale', p.est_principale
            )
          )
          FROM photos_logement p
          WHERE p.logement_id = l.id
        ) as photos,
        (
          SELECT COUNT(*)
          FROM favoris f
          WHERE f.logement_id = l.id
        ) as nombre_favoris,
        (
          SELECT COUNT(*)
          FROM candidatures c
          WHERE c.logement_id = l.id AND c.statut = 'en_attente'
        ) as candidatures_en_attente
      FROM logements l
      WHERE l.proprietaire_id = $1 AND l.est_actif = true
      ORDER BY l.date_creation DESC
      LIMIT $2 OFFSET $3
    `;

    const result = await pool.query(query, [userId, limit, offset]);
    
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
    console.error("Erreur lors de la récupération des logements :", error.message);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

// 🔁 Modifier le profil
// 📤 Upload picture to Downloads folder
const downloadsPath = path.join(__dirname, '..', 'downloads');
const fs = require('fs');
// Ensure the downloads directory exists
if (!fs.existsSync(downloadsPath)) {
  fs.mkdirSync(downloadsPath, { recursive: true });
}
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, downloadsPath);
  },
  filename: function (req, file, cb) {
    // Save with original name; optionally add timestamp for uniqueness
    cb(null, Date.now() + '-' + file.originalname);
  },
});
const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    // Accept any image type by mimetype or extension
    const allowedExt = [
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.tiff', '.ico', '.jfif', '.pjpeg', '.pjp', '.avif', '.apng'
    ];
    const ext = require('path').extname(file.originalname).toLowerCase();
    if (
      (file.mimetype && file.mimetype.startsWith('image/')) ||
      allowedExt.includes(ext)
    ) {
      cb(null, true);
    } else {
      cb(new Error('Seules les images sont autorisées (jpeg, png, gif, webp, bmp, svg, tiff, ico, etc.)'));
    }
  },
});

// POST /api/user/upload-picture/:userId
router.post("/upload-picture/:userId", upload.single("picture"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: "No file uploaded" });
  }

  try {
    // Get user id from route params
    const userId = req.params.userId;
    if (!userId) {
      return res.status(400).json({ message: "User ID is required in URL params" });
    }
    // Insert into photos_utilisateur
    const insertQuery = `INSERT INTO photos_utilisateur (url, utilisateur_id, est_principale) VALUES ($1, $2, $3) RETURNING *`;
    const values = [req.file.path, userId, false];
    const result = await pool.query(insertQuery, values);
    // Build public URL for the uploaded file
    const publicUrl = `${req.protocol}://${req.get('host')}/downloads/${req.file.filename}`;
    res.json({
      message: "File uploaded and saved to DB successfully",
      dbPhoto: result.rows[0],
      filename: req.file.filename,
      url: publicUrl,
    });
  } catch (error) {
    console.error("Erreur lors de l'enregistrement dans la base de données:", error);
    res.status(500).json({ message: "Erreur lors de l'enregistrement dans la base de données" });
  }
});

router.put("/:id", async (req, res) => {
  try {
    const userId = req.params.id;
    const updateFields = {};
    const allowedFields = [
      'nom',
      'prenom',
      'email',
      'mot_de_passe',
      'photo_profil',
      'telephone',
      'date_naissance',
      'sexe',
      'ville'
    ];

    // Check if at least one field is provided
    const hasValidField = allowedFields.some(field => req.body[field] !== undefined);
    if (!hasValidField) {
      return res.status(400).json({ 
        error: "Au moins un champ à modifier doit être fourni",
        allowedFields: allowedFields 
      });
    }

    // Build update fields object
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updateFields[field] = req.body[field];
      }
    });

    // Validate required fields format
    if (updateFields.email && !updateFields.email.includes('@')) {
      return res.status(400).json({ error: "Format d'email invalide" });
    }

    if (updateFields.sexe && !['homme', 'femme'].includes(updateFields.sexe)) {
      return res.status(400).json({ error: "Le sexe doit être 'homme' ou 'femme'" });
    }

    if (updateFields.date_naissance) {
      const date = new Date(updateFields.date_naissance);
      if (isNaN(date.getTime())) {
        return res.status(400).json({ error: "Format de date de naissance invalide" });
      }
    }

    // Build the SQL query dynamically
    const setClause = Object.keys(updateFields)
      .map((key, index) => `${key} = $${index + 1}`)
      .join(', ');
    
    const query = `
      UPDATE users 
      SET ${setClause}
      WHERE id = $${Object.keys(updateFields).length + 1}
      RETURNING id, nom, prenom, email, photo_profil, telephone, date_naissance, sexe, ville, role
    `;

    const values = [...Object.values(updateFields), userId];
    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Utilisateur non trouvé" });
    }

    res.json({
      message: "Profil mis à jour avec succès",
      user: result.rows[0]
    });
  } catch (error) {
    console.error("Erreur lors de la mise à jour du profil :", error.message);
    if (error.constraint === 'users_email_key') {
      return res.status(400).json({ error: "Cet email est déjà utilisé" });
    }
    res.status(500).json({ error: "Erreur serveur" });
  }
});

// ❌ Supprimer le profil
router.delete("/:id", async (req, res) => {
  try {
    await User.deleteById(req.params.id);
    res.json({ message: "Utilisateur supprimé avec succès" });
  } catch (error) {
    console.error("Erreur lors de la suppression du profil :", error.message);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

module.exports = router;
