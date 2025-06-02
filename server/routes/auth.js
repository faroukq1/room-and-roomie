const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const { body, validationResult } = require("express-validator");
const User = require("../models/User");

const SECRET_KEY = process.env.JWT_SECRET || "monSuperSecretJWTKey";

router.get("/", (req, res) => {
  res.json({ message: "Bienvenue sur l'API d'authentification 🚀" });
});

// 🚀 Route d'inscription
router.post(
  "/register",
  [
    body("nom").notEmpty().withMessage("Le nom est requis"),
    body("email").isEmail().withMessage("L'email est invalide"),
    body("mot_de_passe").isLength({ min: 6 }).withMessage("Le mot de passe doit contenir au moins 6 caractères"),
  ],
  async (req, res) => {
    console.log("📥 Données reçues :", req.body); // 🔍 Débugging

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log("❌ Erreurs de validation :", errors.array());
      return res.status(400).json({ errors: errors.array() });
    }

    const { nom, prenom, email, mot_de_passe, role } = req.body;

    try {
      const existingUser = await User.findByEmail(email);
      if (existingUser) return res.status(400).json({ message: "Email déjà utilisé" });

      const newUser = await User.createUser(nom, prenom, email, mot_de_passe, role || "locataire");
      res.status(201).json({ message: "✅ Utilisateur créé", user: newUser });
    } catch (error) {
      console.error("❌ Erreur serveur :", error);
      res.status(500).json({ error: "Erreur serveur" });
    }
  }
);

// 🚀 Route de connexion
router.post(
  "/login",
  [
    body("email").isEmail().withMessage("L'email est invalide"),
    body("mot_de_passe").notEmpty().withMessage("Le mot de passe est requis"),
  ],
  async (req, res) => {
    console.log("📥 Données reçues :", req.body);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log("❌ Erreurs de validation :", errors.array());
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, mot_de_passe } = req.body;

    try {
      const user = await User.findByEmail(email);
      if (!user) return res.status(400).json({ message: "Utilisateur non trouvé" });

      const isMatch = await bcrypt.compare(mot_de_passe, user.mot_de_passe);
      if (!isMatch) return res.status(400).json({ message: "Mot de passe incorrect" });

      const token = jwt.sign({ userId: user.id, role: user.role }, SECRET_KEY, { expiresIn: "1h" });
      res.json({ token, user: { id: user.id, nom: user.nom, email: user.email, role: user.role } });
    } catch (error) {
      console.error("❌ ERREUR SERVEUR :", error.stack); // 🔍 Afficher l'erreur complète
      res.status(500).json({ error: "Erreur serveur" });
    }
  }
);

module.exports = router;
