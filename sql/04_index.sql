-- Index (les clés primaires et les UNIQUE sont déjà indexés)

CREATE INDEX idx_traverse_pays    ON traverse (code_pays);     -- requêtes 2 et 3
CREATE INDEX idx_resultat_etape   ON resultat (id_etape);      -- requête 6
CREATE INDEX idx_compose_personne ON compose (id_personne);    -- requête 7
CREATE INDEX idx_vehicule_marque  ON vehicule (id_marque);     -- requête 5
CREATE INDEX idx_equipage_equipe  ON equipage (id_equipe);
CREATE INDEX idx_personne_nom     ON personne (nom, prenom);   -- tri alphabétique
