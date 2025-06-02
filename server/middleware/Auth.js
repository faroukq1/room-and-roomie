const jwt = require("jsonwebtoken");

const authMiddleware = (req, res, next) => {
  const token = req.header("Authorization")?.replace("Bearer ", "");

  if (!token) return res.status(401).json({ message: "Accès non autorisé, token manquant" });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;  // Ajoute les données de l'utilisateur à la requête
    next();
  } catch (error) {
    console.error("Erreur lors de la vérification du token :", error.message);
    res.status(401).json({ message: "Token invalide" });
  }
};

module.exports = authMiddleware;
