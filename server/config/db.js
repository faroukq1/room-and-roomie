const { Pool } = require('pg');
require('dotenv').config(); // Charge les variables d'environnement depuis .env

const pool = new Pool({
  user: 'postgres', // Ton utilisateur PostgreSQL
  host: 'localhost', // Hôte de la base de données
  database: 'location_colocation', // Nom de ta base
  password: 'alex2002', // Ton mot de passe PostgreSQL
  port: 5432, // Port par défaut
});

module.exports = pool;
