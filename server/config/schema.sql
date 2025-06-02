-- Table Users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    photo_profil VARCHAR(500),
    telephone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'locataire' CHECK (role IN ('locataire', 'proprietaire', 'admin')),
    date_naissance DATE,
    sexe VARCHAR(10) CHECK (sexe IN ('homme', 'femme')),
    ville VARCHAR(100),
    date_inscription TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    est_verifie BOOLEAN DEFAULT FALSE
);



-- Table Logements
CREATE TABLE logements (
    id SERIAL PRIMARY KEY,
    titre VARCHAR(200) NOT NULL,
    description TEXT,
    adresse VARCHAR(300) NOT NULL,
    ville VARCHAR(100) NOT NULL,
    code_postal VARCHAR(10),
    superficie DECIMAL(8,2),
    nombre_pieces INTEGER,
    nombre_coloc_max INTEGER,
    type_logement VARCHAR(50) CHECK (type_logement IN ('appartement', 'maison', 'studio', 'chambre')),
    loyer DECIMAL(10,2) NOT NULL,
    charges_incluses BOOLEAN DEFAULT FALSE,
    meuble BOOLEAN DEFAULT FALSE,
    disponible_a_partir DATE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    est_actif BOOLEAN DEFAULT TRUE,
    capacite_max_colocataires INTEGER,
    proprietaire_id INTEGER NOT NULL,
    FOREIGN KEY (proprietaire_id) REFERENCES users(id) ON DELETE CASCADE
);

select * from logements;

-- Table Colocations
CREATE TABLE colocations (
    id SERIAL PRIMARY KEY,
    description TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logement_id INTEGER NOT NULL,
    createur_id INTEGER NOT NULL,
    FOREIGN KEY (logement_id) REFERENCES logements(id) ON DELETE CASCADE,
    FOREIGN KEY (createur_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table Colocataires
CREATE TABLE colocataires (
    id SERIAL PRIMARY KEY,
    date_entree DATE NOT NULL,
    date_sortie DATE,
    colocation_id INTEGER NOT NULL,
    utilisateur_id INTEGER NOT NULL,
    FOREIGN KEY (colocation_id) REFERENCES colocations(id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(colocation_id, utilisateur_id)
);

-- Table Candidatures
CREATE TABLE candidatures (
    id SERIAL PRIMARY KEY,
    message TEXT,
    date_postulation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'acceptee', 'refusee', 'annulee')),
    logement_id INTEGER NOT NULL,
    locataire_id INTEGER NOT NULL,
    FOREIGN KEY (logement_id) REFERENCES logements(id) ON DELETE CASCADE,
    FOREIGN KEY (locataire_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(logement_id, locataire_id)
);

select * from favoris;


-- Table Favoris
CREATE TABLE favoris (
    id SERIAL PRIMARY KEY,
    date_ajout TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    locataire_id INTEGER NOT NULL,
    logement_id INTEGER NOT NULL,
    FOREIGN KEY (locataire_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (logement_id) REFERENCES logements(id) ON DELETE CASCADE,
    UNIQUE(locataire_id, logement_id)
);

-- Table Messages
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    contenu TEXT NOT NULL,
    date_envoi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lu BOOLEAN DEFAULT FALSE,
    expediteur_id INTEGER NOT NULL,
    destinataire_id INTEGER NOT NULL,
    FOREIGN KEY (expediteur_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (destinataire_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table historique_connexions
CREATE TABLE historique_connexions (
    id SERIAL PRIMARY KEY,
    adresse_ip INET,
    user_agent TEXT,
    date_connexion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    utilisateur_id INTEGER NOT NULL,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table paiements
CREATE TABLE paiements (
    id SERIAL PRIMARY KEY,
    montant DECIMAL(10,2) NOT NULL,
    moyen_paiement VARCHAR(50) CHECK (moyen_paiement IN ('carte_bancaire', 'virement', 'paypal', 'especes', 'cheque')),
    date_paiement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'confirme', 'echoue', 'rembourse')),
    locataire_id INTEGER NOT NULL,
    logement_id INTEGER NOT NULL,
    FOREIGN KEY (locataire_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (logement_id) REFERENCES logements(id) ON DELETE CASCADE
);

-- Table photos_logement
CREATE TABLE photos_logement (
    id SERIAL PRIMARY KEY,
    url VARCHAR(500) NOT NULL,
    est_principale BOOLEAN DEFAULT FALSE,
    logement_id INTEGER NOT NULL,
    FOREIGN KEY (logement_id) REFERENCES logements(id) ON DELETE CASCADE
);

-- Table photos_utilisateur
CREATE TABLE photos_utilisateur (
    id SERIAL PRIMARY KEY,
    url VARCHAR(500) NOT NULL,
    est_principale BOOLEAN DEFAULT FALSE,
    date_ajout TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    utilisateur_id INTEGER NOT NULL,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table notifications
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    titre VARCHAR(200) NOT NULL,
    contenu TEXT,
    type VARCHAR(50) CHECK (type IN ('candidature', 'message', 'paiement', 'systeme', 'rappel')),
    est_lu BOOLEAN DEFAULT FALSE,
    date_envoi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    utilisateur_id INTEGER NOT NULL,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table signalements
CREATE TABLE signalements (
    id SERIAL PRIMARY KEY,
    type_cible VARCHAR(50) CHECK (type_cible IN ('utilisateur', 'logement', 'message', 'autre')),
    cible_id INTEGER NOT NULL,
    raison VARCHAR(500),
    date_signalement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    utilisateur_id INTEGER NOT NULL,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id) ON DELETE CASCADE
);
