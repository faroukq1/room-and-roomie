const express = require("express");
const app = express();
require("dotenv").config(); // ✅ Charger les variables d'environnement
// const cors = require("cors"); // ✅ Ajouter CORS si nécessaire pour les requêtes cross-origin

// Middleware pour parser JSON - DOIT ÊTRE AVANT LES ROUTES
app.use(express.json());
// app.use(cors()); // ✅ Activer CORS (si besoin)

// Importer les routes
const annoncesRoutes = require("./routes/annonces");
const authRoutes = require("./routes/auth");
const userRoutes = require("./routes/user");
const messageRoutes = require("./routes/message"); // ✅ Ajout de la route messages
const statsRoutes = require("./routes/stats");
const logementRoutes = require("./routes/logements");
const colocsRoutes = require("./routes/colocs");
const paymentRoutes = require("./routes/payment");
const notificationRoutes = require("./routes/notification");
// Utilisation des routes
app.use("/api/auth", authRoutes);
app.use("/api/annonces", annoncesRoutes);
app.use("/api/utilisateurs", userRoutes);
app.use("/api/message", messageRoutes); // ✅ Activation des routes de messagerie
app.use("/api/stats", statsRoutes);
app.use("/api/logements", logementRoutes);
app.use("/api/colocs", colocsRoutes);
app.use("/api/paiements", paymentRoutes);
app.use("/api/notifications", notificationRoutes);
// ➕ Serve downloads folder statically
const path = require('path');
app.use('/downloads', express.static(path.join(__dirname, 'downloads')));
// Middleware de gestion des erreurs globales
app.use((err, req, res, next) => {
    console.error("❌ Erreur serveur :", err.message);
    res.status(500).json({ error: "Erreur serveur", details: err.message });
});

// Configuration du port à partir des variables d'environnement ou d'un port par défaut
const PORT = process.env.PORT || 5050;
app.listen(PORT, () => {
    console.log(`✅ Server running on http://localhost:${PORT}`);
});
