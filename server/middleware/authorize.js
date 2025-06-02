const User = require("../models/User");

const authorizeMiddleware = async (req, res, next) => {
  const { id } = req.params;

  if (req.user.id !== parseInt(id)) {
    return res.status(403).json({ message: "Vous n'êtes pas autorisé à accéder à ce profil" });
  }

  next();
};

module.exports = authorizeMiddleware;
