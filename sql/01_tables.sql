-- Création des tables
-- psql -d rallye -f sql/01_tables.sql

DROP TABLE IF EXISTS utilisateur, resultat, compose, vehicule, equipage, sponsorise_equipe,
    regroupe, equipe, traverse, etape, fournit, sponsorise_rallye, fournisseur, sponsor,
    organise, organisateur, concurrent, personne, rallye, marque, pays CASCADE;


CREATE TABLE pays (
    code CHAR(2) PRIMARY KEY,
    nom  VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE marque (
    id_marque SERIAL PRIMARY KEY,
    nom       VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE rallye (
    id_rallye SERIAL PRIMARY KEY,
    nom       VARCHAR(100) NOT NULL,
    annee     INTEGER NOT NULL CHECK (annee BETWEEN 1950 AND 2100),
    UNIQUE (nom, annee)
);


-- personne / concurrent / organisateur : une table par sous-type
CREATE TABLE personne (
    id_personne   SERIAL PRIMARY KEY,
    nom           VARCHAR(50) NOT NULL,
    prenom        VARCHAR(50) NOT NULL,
    adresse_rue   VARCHAR(100) NOT NULL,
    adresse_cp    VARCHAR(10) NOT NULL,
    adresse_ville VARCHAR(60) NOT NULL,
    adresse_pays  VARCHAR(60) NOT NULL
);

CREATE TABLE concurrent (
    id_personne INTEGER PRIMARY KEY REFERENCES personne ON DELETE CASCADE,
    nationalite VARCHAR(50) NOT NULL
);

CREATE TABLE organisateur (
    id_personne INTEGER PRIMARY KEY REFERENCES personne ON DELETE CASCADE,
    fonction    VARCHAR(50) NOT NULL
);

CREATE TABLE organise (
    id_personne INTEGER REFERENCES organisateur ON DELETE CASCADE,
    id_rallye   INTEGER REFERENCES rallye ON DELETE CASCADE,
    PRIMARY KEY (id_personne, id_rallye)
);


CREATE TABLE sponsor (
    id_sponsor SERIAL PRIMARY KEY,
    nom        VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE fournisseur (
    id_fournisseur  SERIAL PRIMARY KEY,
    nom             VARCHAR(100) NOT NULL UNIQUE,
    type_fourniture VARCHAR(50) NOT NULL
);

CREATE TABLE sponsorise_rallye (
    id_sponsor INTEGER REFERENCES sponsor ON DELETE CASCADE,
    id_rallye  INTEGER REFERENCES rallye ON DELETE CASCADE,
    PRIMARY KEY (id_sponsor, id_rallye)
);

CREATE TABLE fournit (
    id_fournisseur INTEGER REFERENCES fournisseur ON DELETE CASCADE,
    id_rallye      INTEGER REFERENCES rallye ON DELETE CASCADE,
    PRIMARY KEY (id_fournisseur, id_rallye)
);


-- liaison et spéciale dans la même table
CREATE TABLE etape (
    id_etape        SERIAL PRIMARY KEY,
    id_rallye       INTEGER NOT NULL REFERENCES rallye ON DELETE CASCADE,
    numero          INTEGER NOT NULL CHECK (numero > 0),
    ville_depart    VARCHAR(60) NOT NULL,
    ville_arrivee   VARCHAR(60) NOT NULL,
    distance_km     NUMERIC(6,1) NOT NULL CHECK (distance_km > 0),
    type_etape      VARCHAR(10) NOT NULL CHECK (type_etape IN ('liaison', 'speciale')),
    heure_ouverture TIME,
    heure_fermeture TIME,
    UNIQUE (id_rallye, numero),
    -- tranche horaire seulement pour les spéciales
    CONSTRAINT ck_etape_tranche CHECK (
        (type_etape = 'speciale' AND heure_ouverture IS NOT NULL AND heure_fermeture IS NOT NULL
            AND heure_ouverture < heure_fermeture)
        OR (type_etape = 'liaison' AND heure_ouverture IS NULL AND heure_fermeture IS NULL)
    )
);

CREATE TABLE traverse (
    id_etape  INTEGER REFERENCES etape ON DELETE CASCADE,
    code_pays CHAR(2) REFERENCES pays,
    PRIMARY KEY (id_etape, code_pays)
);


-- officielle et association dans la même table
CREATE TABLE equipe (
    id_equipe   SERIAL PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL UNIQUE,
    budget      NUMERIC(12,2) NOT NULL CHECK (budget >= 0),
    type_equipe VARCHAR(12) NOT NULL CHECK (type_equipe IN ('officielle', 'association')),
    id_marque   INTEGER REFERENCES marque,   -- marque représentée si officielle
    CONSTRAINT ck_equipe_marque CHECK ((type_equipe = 'officielle') = (id_marque IS NOT NULL))
);

CREATE TABLE regroupe (
    id_equipe INTEGER REFERENCES equipe ON DELETE CASCADE,
    id_marque INTEGER REFERENCES marque,
    PRIMARY KEY (id_equipe, id_marque)
);

CREATE TABLE sponsorise_equipe (
    id_sponsor INTEGER REFERENCES sponsor ON DELETE CASCADE,
    id_equipe  INTEGER REFERENCES equipe ON DELETE CASCADE,
    PRIMARY KEY (id_sponsor, id_equipe)
);


CREATE TABLE equipage (
    id_equipage SERIAL PRIMARY KEY,
    id_rallye   INTEGER NOT NULL REFERENCES rallye ON DELETE CASCADE,
    numero      INTEGER NOT NULL CHECK (numero > 0),
    id_equipe   INTEGER NOT NULL REFERENCES equipe,
    UNIQUE (id_rallye, numero)
);

-- court_sur (1-1)
CREATE TABLE vehicule (
    id_vehicule SERIAL PRIMARY KEY,
    num_serie   VARCHAR(30) NOT NULL UNIQUE,
    num_course  INTEGER NOT NULL CHECK (num_course > 0),
    cylindree   INTEGER NOT NULL CHECK (cylindree > 0),
    categorie   VARCHAR(10) NOT NULL CHECK (categorie IN ('Auto', 'Camion', 'Moto')),
    id_marque   INTEGER NOT NULL REFERENCES marque,
    id_equipage INTEGER NOT NULL UNIQUE REFERENCES equipage ON DELETE CASCADE
);

CREATE TABLE compose (
    id_equipage INTEGER REFERENCES equipage ON DELETE CASCADE,
    id_personne INTEGER REFERENCES concurrent ON DELETE CASCADE,
    PRIMARY KEY (id_equipage, id_personne)
);

-- temps NULL = abandon
CREATE TABLE resultat (
    id_equipage   INTEGER REFERENCES equipage ON DELETE CASCADE,
    id_etape      INTEGER REFERENCES etape ON DELETE CASCADE,
    temps         INTERVAL CHECK (temps >= INTERVAL '0'),
    heure_arrivee TIME,
    disqualifie   BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_equipage, id_etape)
);


-- comptes de l'application
CREATE TABLE utilisateur (
    id_utilisateur SERIAL PRIMARY KEY,
    login          VARCHAR(30) NOT NULL UNIQUE,
    mot_de_passe   VARCHAR(255) NOT NULL,
    role           VARCHAR(15) NOT NULL CHECK (role IN ('organisateur', 'visiteur'))
);
