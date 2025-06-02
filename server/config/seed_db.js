require('dotenv').config();
const { Pool } = require('pg');
const faker = require('faker');
faker.locale = 'fr';

// Database configuration (use environment variables)
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'location_colocation',
  password: process.env.DB_PASSWORD || 'aa',
  port: process.env.DB_PORT || 5432,
});

// ... rest of the seed script remains the same ...

// Data generation limits (total records: 995)
const RECORD_LIMITS = {
  users: 100,
  logements: 80,
  colocations: 70,
  colocataires: 150,
  candidatures: 150,
  favoris: 100,
  messages: 100,
  historique_connexions: 50,
  paiements: 50,
  photos_logement: 100,
  photos_utilisateur: 50,
  notifications: 50,
  signalements: 45
};

async function seedDatabase() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // 1. Generate Users
    const users = Array.from({length: RECORD_LIMITS.users}, () => ({
      nom: faker.name.lastName(),
      prenom: faker.name.firstName(),
      email: faker.internet.email(),
      mot_de_passe: faker.internet.password(),
      photo_profil: faker.image.avatar(),
      telephone: faker.phone.phoneNumber(),
      role: faker.random.arrayElement(['locataire', 'proprietaire', 'admin']),
      date_naissance: faker.date.past(30, '2003-01-01'),
      sexe: faker.random.arrayElement(['homme', 'femme']),
      ville: faker.address.city(),
      est_verifie: faker.datatype.boolean()
    }));

    const userRes = await client.query(
      `INSERT INTO users (
        nom, prenom, email, mot_de_passe, photo_profil, telephone, role, 
        date_naissance, sexe, ville, est_verifie
      ) VALUES ${generatePlaceholders(users, 11)} RETURNING id`,
      users.flatMap(u => [
        u.nom, u.prenom, u.email, u.mot_de_passe, u.photo_profil, u.telephone, u.role,
        u.date_naissance, u.sexe, u.ville, u.est_verifie
      ])
    );
    const userIds = userRes.rows.map(row => row.id);
    const proprietaireIds = userIds.filter((_, i) => users[i].role === 'proprietaire');
    
    // 2. Generate Logements
    const logements = Array.from({length: RECORD_LIMITS.logements}, () => ({
      titre: faker.lorem.words(3),
      description: faker.lorem.paragraph(),
      adresse: faker.address.streetAddress(),
      ville: faker.address.city(),
      code_postal: faker.address.zipCode(),
      superficie: faker.datatype.number({min: 20, max: 200}),
      nombre_pieces: faker.datatype.number({min: 1, max: 6}),
      nombre_coloc_max: faker.datatype.number({min: 2, max: 6}),
      type_logement: faker.random.arrayElement(['appartement', 'maison', 'studio', 'chambre']),
      loyer: faker.datatype.number({min: 300, max: 1500, precision: 0.01}),
      charges_incluses: faker.datatype.boolean(),
      meuble: faker.datatype.boolean(),
      disponible_a_partir: faker.date.future(),
      est_actif: faker.datatype.boolean(),
      capacite_max_colocataires: faker.datatype.number({min: 2, max: 8}),
      proprietaire_id: faker.random.arrayElement(proprietaireIds)
    }));

    const logementRes = await client.query(
      `INSERT INTO logements (
        titre, description, adresse, ville, code_postal, superficie, nombre_pieces,
        nombre_coloc_max, type_logement, loyer, charges_incluses, meuble, 
        disponible_a_partir, est_actif, capacite_max_colocataires, proprietaire_id
      ) VALUES ${generatePlaceholders(logements, 16)} RETURNING id`,
      logements.flatMap(l => [
        l.titre, l.description, l.adresse, l.ville, l.code_postal, l.superficie, l.nombre_pieces,
        l.nombre_coloc_max, l.type_logement, l.loyer, l.charges_incluses, l.meuble,
        l.disponible_a_partir, l.est_actif, l.capacite_max_colocataires, l.proprietaire_id
      ])
    );
    const logementIds = logementRes.rows.map(row => row.id);
    
    // 3. Generate Colocations
    const colocations = Array.from({length: RECORD_LIMITS.colocations}, () => ({
      description: faker.lorem.sentence(),
      logement_id: faker.random.arrayElement(logementIds),
      createur_id: faker.random.arrayElement(userIds)
    }));

    const colocRes = await client.query(
      `INSERT INTO colocations (description, logement_id, createur_id)
       VALUES ${generatePlaceholders(colocations, 3)} RETURNING id`,
      colocations.flatMap(c => [c.description, c.logement_id, c.createur_id])
    );
    const colocIds = colocRes.rows.map(row => row.id);
    
    // 4. Generate Colocataires (with unique constraint handling)
    const colocataires = [];
    const colocPairs = new Set();
    
    for (let i = 0; i < RECORD_LIMITS.colocataires; i++) {
      let colocationId, utilisateurId;
      
      do {
        colocationId = faker.random.arrayElement(colocIds);
        utilisateurId = faker.random.arrayElement(userIds);
      } while (colocPairs.has(`${colocationId}-${utilisateurId}`));
      
      colocPairs.add(`${colocationId}-${utilisateurId}`);
      
      colocataires.push({
        date_entree: faker.date.past(1),
        date_sortie: faker.datatype.boolean() ? faker.date.future() : null,
        colocation_id: colocationId,
        utilisateur_id: utilisateurId
      });
    }

    await client.query(
      `INSERT INTO colocataires (date_entree, date_sortie, colocation_id, utilisateur_id)
       VALUES ${generatePlaceholders(colocataires, 4)}`,
      colocataires.flatMap(c => [
        c.date_entree, c.date_sortie, c.colocation_id, c.utilisateur_id
      ])
    );
    
    // 5. Generate Candidatures (with unique constraint handling)
    const candidatures = [];
    const candPairs = new Set();
    
    for (let i = 0; i < RECORD_LIMITS.candidatures; i++) {
      let logementId, locataireId;
      
      do {
        logementId = faker.random.arrayElement(logementIds);
        locataireId = faker.random.arrayElement(userIds);
      } while (candPairs.has(`${logementId}-${locataireId}`));
      
      candPairs.add(`${logementId}-${locataireId}`);
      
      candidatures.push({
        message: faker.lorem.paragraph(),
        statut: faker.random.arrayElement(['en_attente', 'acceptee', 'refusee', 'annulee']),
        logement_id: logementId,
        locataire_id: locataireId
      });
    }

    await client.query(
      `INSERT INTO candidatures (message, statut, logement_id, locataire_id)
       VALUES ${generatePlaceholders(candidatures, 4)}`,
      candidatures.flatMap(c => [
        c.message, c.statut, c.logement_id, c.locataire_id
      ])
    );
    
    // 6. Generate Favoris (with unique constraint handling)
    const favoris = [];
    const favPairs = new Set();
    
    for (let i = 0; i < RECORD_LIMITS.favoris; i++) {
      let locataireId, logementId;
      
      do {
        locataireId = faker.random.arrayElement(userIds);
        logementId = faker.random.arrayElement(logementIds);
      } while (favPairs.has(`${locataireId}-${logementId}`));
      
      favPairs.add(`${locataireId}-${logementId}`);
      
      favoris.push({
        locataire_id: locataireId,
        logement_id: logementId
      });
    }

    await client.query(
      `INSERT INTO favoris (locataire_id, logement_id)
       VALUES ${generatePlaceholders(favoris, 2)}`,
      favoris.flatMap(f => [f.locataire_id, f.logement_id])
    );
    
    // 7. Generate Messages
    const messages = Array.from({length: RECORD_LIMITS.messages}, () => {
      const [expediteur, destinataire] = faker.helpers.shuffle(userIds).slice(0, 2);
      return {
        contenu: faker.lorem.paragraph(),
        lu: faker.datatype.boolean(),
        expediteur_id: expediteur,
        destinataire_id: destinataire
      };
    });

    await client.query(
      `INSERT INTO messages (contenu, lu, expediteur_id, destinataire_id)
       VALUES ${generatePlaceholders(messages, 4)}`,
      messages.flatMap(m => [
        m.contenu, m.lu, m.expediteur_id, m.destinataire_id
      ])
    );
    
    // 8. Generate Historique Connexions
    const historique = Array.from({length: RECORD_LIMITS.historique_connexions}, () => ({
      adresse_ip: faker.internet.ip(),
      user_agent: faker.internet.userAgent(),
      utilisateur_id: faker.random.arrayElement(userIds)
    }));

    await client.query(
      `INSERT INTO historique_connexions (adresse_ip, user_agent, utilisateur_id)
       VALUES ${generatePlaceholders(historique, 3)}`,
      historique.flatMap(h => [h.adresse_ip, h.user_agent, h.utilisateur_id])
    );
    
    // 9. Generate Paiements
    const paiements = Array.from({length: RECORD_LIMITS.paiements}, () => ({
      montant: faker.datatype.number({min: 300, max: 1200, precision: 0.01}),
      moyen_paiement: faker.random.arrayElement(['carte_bancaire', 'virement', 'paypal', 'especes', 'cheque']),
      statut: faker.random.arrayElement(['en_attente', 'confirme', 'echoue', 'rembourse']),
      locataire_id: faker.random.arrayElement(userIds),
      logement_id: faker.random.arrayElement(logementIds)
    }));

    await client.query(
      `INSERT INTO paiements (montant, moyen_paiement, statut, locataire_id, logement_id)
       VALUES ${generatePlaceholders(paiements, 5)}`,
      paiements.flatMap(p => [
        p.montant, p.moyen_paiement, p.statut, p.locataire_id, p.logement_id
      ])
    );
    
    // 10. Generate Photos Logement
    const photosLogement = [];
    logementIds.forEach(id => {
      const count = faker.datatype.number({min: 1, max: 3});
      for (let i = 0; i < count && photosLogement.length < RECORD_LIMITS.photos_logement; i++) {
        photosLogement.push({
          url: faker.image.imageUrl(),
          est_principale: i === 0,
          logement_id: id
        });
      }
    });

    await client.query(
      `INSERT INTO photos_logement (url, est_principale, logement_id)
       VALUES ${generatePlaceholders(photosLogement, 3)}`,
      photosLogement.flatMap(p => [p.url, p.est_principale, p.logement_id])
    );
    
    // 11. Generate Photos Utilisateur
    const photosUtilisateur = userIds.map(id => ({
      url: faker.image.avatar(),
      est_principale: true,
      utilisateur_id: id
    }));

    await client.query(
      `INSERT INTO photos_utilisateur (url, est_principale, utilisateur_id)
       VALUES ${generatePlaceholders(photosUtilisateur, 3)}`,
      photosUtilisateur.flatMap(p => [p.url, p.est_principale, p.utilisateur_id])
    );
    
    // 12. Generate Notifications
    const notifications = Array.from({length: RECORD_LIMITS.notifications}, () => ({
      titre: faker.lorem.words(3),
      contenu: faker.lorem.sentence(),
      type: faker.random.arrayElement(['candidature', 'message', 'paiement', 'systeme', 'rappel']),
      est_lu: faker.datatype.boolean(),
      utilisateur_id: faker.random.arrayElement(userIds)
    }));

    await client.query(
      `INSERT INTO notifications (titre, contenu, type, est_lu, utilisateur_id)
       VALUES ${generatePlaceholders(notifications, 5)}`,
      notifications.flatMap(n => [
        n.titre, n.contenu, n.type, n.est_lu, n.utilisateur_id
      ])
    );
    
    // 13. Generate Signalements
    const signalements = Array.from({length: RECORD_LIMITS.signalements}, () => ({
      type_cible: faker.random.arrayElement(['utilisateur', 'logement', 'message', 'autre']),
      cible_id: faker.datatype.number(1000),
      raison: faker.lorem.sentence(),
      utilisateur_id: faker.random.arrayElement(userIds)
    }));

    await client.query(
      `INSERT INTO signalements (type_cible, cible_id, raison, utilisateur_id)
       VALUES ${generatePlaceholders(signalements, 4)}`,
      signalements.flatMap(s => [
        s.type_cible, s.cible_id, s.raison, s.utilisateur_id
      ])
    );

    await client.query('COMMIT');
    console.log('Database seeded successfully! Total records:', Object.values(RECORD_LIMITS).reduce((a, b) => a + b, 0));
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seeding failed:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

// Helper function to generate SQL placeholders
function generatePlaceholders(data, columns) {
  return data.map((_, i) => 
    `(${Array.from({length: columns}, (_, j) => `$${i * columns + j + 1}`).join(',')})`
  ).join(',');
}

seedDatabase();