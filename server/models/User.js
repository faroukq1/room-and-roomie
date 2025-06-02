// Fixed User Model
const pool = require("../config");
const bcrypt = require('bcryptjs');

class User {
  // Create user with required fields (nom, prenom, email, mot_de_passe)
  static async createUser(nom, prenom, email, mot_de_passe, role = 'locataire') {
    try {
      const hashedPassword = await bcrypt.hash(mot_de_passe, 10);
      
      const result = await pool.query(
        `INSERT INTO users (nom, prenom, email, mot_de_passe, role) 
         VALUES ($1, $2, $3, $4, $5) 
         RETURNING id, nom, prenom, email, role, date_inscription, est_verifie`,
        [nom, prenom, email, hashedPassword, role]
      );
      
      return result.rows[0];
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }

  // Create user with complete data object
  static async createUserComplete(userData) {
    const { 
      nom, 
      prenom, 
      email, 
      mot_de_passe, 
      role = 'locataire',
      telephone = null,
      date_naissance = null,
      sexe = null,
      ville = null,
      photo_profil = null
    } = userData;

    try {
      const hashedPassword = await bcrypt.hash(mot_de_passe, 10);
      
      const result = await pool.query(`
        INSERT INTO users (
          nom, prenom, email, mot_de_passe, role, 
          telephone, date_naissance, sexe, ville, photo_profil
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
        RETURNING id, nom, prenom, email, role, telephone, 
                  date_naissance, sexe, ville, photo_profil, 
                  date_inscription, est_verifie
      `, [
        nom, prenom, email, hashedPassword, role,
        telephone, date_naissance, sexe, ville, photo_profil
      ]);
      
      return result.rows[0];
    } catch (error) {
      console.error('Error creating complete user:', error);
      throw error;
    }
  }

  // Find user by email
  static async findByEmail(email) {
    try {
      const result = await pool.query(
        'SELECT * FROM users WHERE email = $1', 
        [email]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error finding user by email:', error);
      throw error;
    }
  }

  // Get user by ID (without password)
  static async getById(id) {
    try {
      const result = await pool.query(
        `SELECT id, nom, prenom, email, role, telephone, date_naissance, 
                sexe, ville, photo_profil, date_inscription, est_verifie 
         FROM users WHERE id = $1`,
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error getting user by ID:', error);
      throw error;
    }
  }

  // Update user profile
  static async updateProfile(id, updateData) {
    const { nom, prenom, email, mot_de_passe, role, telephone, date_naissance, sexe, ville, photo_profil } = updateData;
    
    try {
      let hashedPassword = null;
      
      // Hash password if provided
      if (mot_de_passe && mot_de_passe.trim() !== '') {
        hashedPassword = await bcrypt.hash(mot_de_passe, 10);
      }

      // Build dynamic query based on provided fields
      const fields = [];
      const values = [];
      let paramCount = 1;

      if (nom !== undefined) {
        fields.push(`nom = $${paramCount}`);
        values.push(nom);
        paramCount++;
      }
      
      if (prenom !== undefined) {
        fields.push(`prenom = $${paramCount}`);
        values.push(prenom);
        paramCount++;
      }
      
      if (email !== undefined) {
        fields.push(`email = $${paramCount}`);
        values.push(email);
        paramCount++;
      }
      
      if (hashedPassword) {
        fields.push(`mot_de_passe = $${paramCount}`);
        values.push(hashedPassword);
        paramCount++;
      }
      
      if (role !== undefined) {
        fields.push(`role = $${paramCount}`);
        values.push(role);
        paramCount++;
      }
      
      if (telephone !== undefined) {
        fields.push(`telephone = $${paramCount}`);
        values.push(telephone);
        paramCount++;
      }
      
      if (date_naissance !== undefined) {
        fields.push(`date_naissance = $${paramCount}`);
        values.push(date_naissance);
        paramCount++;
      }
      
      if (sexe !== undefined) {
        fields.push(`sexe = $${paramCount}`);
        values.push(sexe);
        paramCount++;
      }
      
      if (ville !== undefined) {
        fields.push(`ville = $${paramCount}`);
        values.push(ville);
        paramCount++;
      }
      
      if (photo_profil !== undefined) {
        fields.push(`photo_profil = $${paramCount}`);
        values.push(photo_profil);
        paramCount++;
      }

      if (fields.length === 0) {
        throw new Error('No fields to update');
      }

      values.push(id);

      const result = await pool.query(
        `UPDATE users SET ${fields.join(', ')} 
         WHERE id = $${paramCount} 
         RETURNING id, nom, prenom, email, role, telephone, date_naissance, 
                   sexe, ville, photo_profil, date_inscription, est_verifie`,
        values
      );
      
      return result.rows[0];
    } catch (error) {
      console.error('Error updating user profile:', error);
      throw error;
    }
  }

  // Simple update profile (backward compatibility)
  static async updateProfileSimple(id, nom, prenom, email, mot_de_passe, role) {
    return this.updateProfile(id, { nom, prenom, email, mot_de_passe, role });
  }

  // Delete user by ID
  static async deleteById(id) {
    try {
      const result = await pool.query(
        "DELETE FROM users WHERE id = $1 RETURNING *", 
        [id]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error deleting user:', error);
      throw error;
    }
  }

  // Verify password
  static async verifyPassword(plainPassword, hashedPassword) {
    try {
      return await bcrypt.compare(plainPassword, hashedPassword);
    } catch (error) {
      console.error('Error verifying password:', error);
      return false;
    }
  }

  // Check if email exists
  static async emailExists(email, excludeId = null) {
    try {
      let query = 'SELECT id FROM users WHERE email = $1';
      let values = [email];
      
      if (excludeId) {
        query += ' AND id != $2';
        values.push(excludeId);
      }
      
      const result = await pool.query(query, values);
      return result.rows.length > 0;
    } catch (error) {
      console.error('Error checking email existence:', error);
      throw error;
    }
  }

  // Get all users (admin function)
  static async getAllUsers(limit = 50, offset = 0) {
    try {
      const result = await pool.query(`
        SELECT id, nom, prenom, email, role, ville, telephone,
               date_inscription, est_verifie 
        FROM users 
        ORDER BY date_inscription DESC 
        LIMIT $1 OFFSET $2
      `, [limit, offset]);
      
      return result.rows;
    } catch (error) {
      console.error('Error getting all users:', error);
      throw error;
    }
  }

  // Update user verification status
  static async verifyUser(userId) {
    try {
      const result = await pool.query(
        'UPDATE users SET est_verifie = true WHERE id = $1 RETURNING *',
        [userId]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error verifying user:', error);
      throw error;
    }
  }

  // Search users by name or email
  static async searchUsers(searchTerm, limit = 20) {
    try {
      const result = await pool.query(`
        SELECT id, nom, prenom, email, role, ville, date_inscription, est_verifie
        FROM users 
        WHERE nom ILIKE $1 OR prenom ILIKE $1 OR email ILIKE $1
        ORDER BY nom, prenom
        LIMIT $2
      `, [`%${searchTerm}%`, limit]);
      
      return result.rows;
    } catch (error) {
      console.error('Error searching users:', error);
      throw error;
    }
  }
}

module.exports = User;