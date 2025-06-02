const express = require("express");
const router = express.Router();
const Message = require("../models/Message");
const authMiddleware = require("../middleware/Auth"); // Assurez-vous que ce fichier existe

// 📩 Envoyer un message
router.post("/", authMiddleware, async (req, res) => {
  const { destinataire_id, contenu } = req.body;
  const expediteur_id = req.user.userId;  // Assurez-vous que 'userId' est bien dans le JWT

  // Vérifier si les données nécessaires sont présentes
  if (!destinataire_id || !contenu) {
    return res.status(400).json({ error: "Destinataire et contenu requis" });
  }

  try {
    // Créer un nouveau message
    const result = await Message.create({
      expediteur_id, 
      destinataire_id, 
      contenu
    });

    res.status(201).json({ message: "Message envoyé", id: result.id });
  } catch (err) {
    console.error("Erreur lors de l’envoi du message : ", err);
    res.status(500).json({ error: "Erreur lors de l’envoi" });
  }
});

// 📬 Récupérer tous les messages entre deux users
router.get("/:id", authMiddleware, async (req, res) => {
  const destinataire_id = req.params.id;
  const expediteur_id = req.user.userId;

  try {
    const messages = await Message.getMessagesBetweenUsers(expediteur_id, destinataire_id);

    // Vérifier si des messages existent
    if (!messages || messages.length === 0) {
      return res.status(404).json({ message: "Aucun message trouvé" });
    }

    res.json(messages);
  } catch (err) {
    console.error("Erreur lors de la récupération des messages : ", err);
    res.status(500).json({ error: "Erreur lors de la récupération" });
  }
});

module.exports = router;
