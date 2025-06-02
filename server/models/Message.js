const db = require("../config/db");

const Message = {
  create: async (expediteur_id, destinataire_id, contenu) => {
    const result = await db.query(
      "INSERT INTO messages (expediteur_id, destinataire_id, contenu) VALUES ($1, $2, $3) RETURNING *",
      [expediteur_id, destinataire_id, contenu]
    );
    return result.rows[0];
  },

  getMessagesBetweenUsers: async (user1, user2) => {
    const result = await db.query(
      `SELECT * FROM messages 
       WHERE (expediteur_id = $1 AND destinataire_id = $2)
          OR (expediteur_id = $2 AND destinataire_id = $1)
       ORDER BY date_envoi ASC`,
      [user1, user2]
    );
    return result.rows;
  }
};

module.exports = Message;
