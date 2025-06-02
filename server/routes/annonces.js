const express = require("express");
const router = express.Router();
const { body, validationResult, param } = require("express-validator");
const Annonce = require("../models/Annonces"); // ✅ Vérifie que le modèle existe et contient les bonnes méthodes

const TYPE_LOGEMENTS = ["studio", "appartement", "colocation", "maison"];

// ✅ Middleware pour gérer les erreurs async
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// ✅ Récupérer toutes les annonces
router.get("/", asyncHandler(async (req, res) => {
  const annonces = await Annonce.getAnnonces();
  res.json(annonces);
}));

// ✅ Récupérer une annonce par ID
router.get("/:id", 
  param("id").isInt().withMessage("L'ID doit être un entier"),
  asyncHandler(async (req, res) => {
    const annonce = await Annonce.getAnnonceById(req.params.id);
    if (!annonce) return res.status(404).json({ message: "Annonce non trouvée" });
    res.json(annonce);
  })
);

// ✅ Créer une nouvelle annonce
router.post("/", [
    body("proprietaire_id").isInt().withMessage("L'ID du propriétaire est requis"),
    body("titre").notEmpty().withMessage("Le titre est requis"),
    body("description").notEmpty().withMessage("La description est requise"),
    body("prix").isNumeric().withMessage("Le prix doit être un nombre"),
    body("adresse").notEmpty().withMessage("L'adresse est requise"),
    body("ville").notEmpty().withMessage("La ville est requise"),
    body("type_logement").isIn(TYPE_LOGEMENTS).withMessage("Type de logement invalide"),
    body("disponibilite").isBoolean().withMessage("La disponibilité doit être true ou false"),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const { proprietaire_id, titre, description, prix, adresse, ville, type_logement, disponibilite } = req.body;
    const nouvelleAnnonce = await Annonce.createAnnonce(proprietaire_id, titre, description, prix, adresse, ville, type_logement, disponibilite);
    res.status(201).json(nouvelleAnnonce);
  })
);

// ✅ Modifier une annonce
router.put("/:id", [
    param("id").isInt().withMessage("L'ID doit être un entier"),
    body("type_logement").optional().isIn(TYPE_LOGEMENTS).withMessage("Type de logement invalide"),
  ],
  asyncHandler(async (req, res) => {
    const { titre, description, prix, adresse, ville, type_logement, disponibilite } = req.body;
    
    const annonce = await Annonce.updateAnnonce(req.params.id, titre, description, prix, adresse, ville, type_logement, disponibilite);
    if (!annonce) return res.status(404).json({ message: "Annonce non trouvée" });
    res.json(annonce);
  })
);

// ✅ Supprimer une annonce
router.delete("/:id", 
  param("id").isInt().withMessage("L'ID doit être un entier"),
  asyncHandler(async (req, res) => {
    await Annonce.deleteAnnonce(req.params.id);
    res.json({ message: "Annonce supprimée" });
  })
);

// ✅ Recherche d'annonces avec des filtres
router.get("/search", async (req, res) => {
  const { ville, prix_min, prix_max, type_logement } = req.query; // Récupérer les filtres envoyés par l'utilisateur

  try {
    // On appelle une fonction qui va chercher les annonces dans la base de données avec les filtres
    const filteredAnnonces = await Annonce.searchAnnonces(ville, prix_min, prix_max, type_logement);
    res.json(filteredAnnonces); // Retourner les annonces filtrées
  } catch (error) {
    console.error("❌ Erreur serveur :", error);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

module.exports = router;
