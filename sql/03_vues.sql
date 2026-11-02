-- Vues

-- concurrents avec leur équipage, rallye, équipe et véhicule
CREATE OR REPLACE VIEW v_participant AS
SELECT p.id_personne, p.nom, p.prenom, c.nationalite,
       r.id_rallye, r.nom AS rallye, r.annee,
       e.id_equipage, e.numero AS num_equipage,
       eq.nom AS equipe, eq.type_equipe,
       v.num_course, v.categorie, m.nom AS marque
FROM compose co
JOIN concurrent c  ON c.id_personne = co.id_personne
JOIN personne p    ON p.id_personne = c.id_personne
JOIN equipage e    ON e.id_equipage = co.id_equipage
JOIN rallye r      ON r.id_rallye = e.id_rallye
JOIN equipe eq     ON eq.id_equipe = e.id_equipe
LEFT JOIN vehicule v ON v.id_equipage = e.id_equipage
LEFT JOIN marque m   ON m.id_marque = v.id_marque;


-- étapes avec les pays traversés
CREATE OR REPLACE VIEW v_etape_pays AS
SELECT r.id_rallye, r.nom AS rallye, r.annee,
       et.id_etape, et.numero, et.ville_depart, et.ville_arrivee, et.distance_km, et.type_etape,
       pa.code AS code_pays, pa.nom AS pays
FROM etape et
JOIN rallye r   ON r.id_rallye = et.id_rallye
JOIN traverse t ON t.id_etape = et.id_etape
JOIN pays pa    ON pa.code = t.code_pays;


-- classement de chaque étape (pas de rang pour les disqualifiés et les abandons)
CREATE OR REPLACE VIEW v_classement_etape AS
SELECT r.id_rallye, r.nom AS rallye, r.annee,
       et.id_etape, et.numero AS num_etape,
       e.id_equipage, e.numero AS num_equipage, eq.nom AS equipe,
       res.temps, res.heure_arrivee, res.disqualifie,
       CASE WHEN res.disqualifie OR res.temps IS NULL THEN NULL
            ELSE RANK() OVER (PARTITION BY et.id_etape, (res.disqualifie OR res.temps IS NULL)
                              ORDER BY res.temps)
       END AS rang
FROM resultat res
JOIN etape et    ON et.id_etape = res.id_etape
JOIN rallye r    ON r.id_rallye = et.id_rallye
JOIN equipage e  ON e.id_equipage = res.id_equipage
JOIN equipe eq   ON eq.id_equipe = e.id_equipe;


-- classement général : équipages qui ont fini toutes les étapes sans disqualification
CREATE OR REPLACE VIEW v_classement_general AS
SELECT e.id_rallye, e.id_equipage, e.numero AS num_equipage, eq.nom AS equipe,
       SUM(res.temps) AS temps_total,
       RANK() OVER (PARTITION BY e.id_rallye ORDER BY SUM(res.temps)) AS rang
FROM equipage e
JOIN equipe eq    ON eq.id_equipe = e.id_equipe
JOIN resultat res ON res.id_equipage = e.id_equipage
GROUP BY e.id_rallye, e.id_equipage, e.numero, eq.nom
HAVING BOOL_AND(NOT res.disqualifie AND res.temps IS NOT NULL)
   AND COUNT(*) = (SELECT COUNT(*) FROM etape et WHERE et.id_rallye = e.id_rallye);


-- nombre de participations par concurrent et par rallye
CREATE OR REPLACE VIEW v_participations AS
SELECT p.id_personne, p.nom, p.prenom, r.nom AS rallye, COUNT(*) AS nb_participations
FROM compose co
JOIN personne p  ON p.id_personne = co.id_personne
JOIN equipage e  ON e.id_equipage = co.id_equipage
JOIN rallye r    ON r.id_rallye = e.id_rallye
GROUP BY p.id_personne, p.nom, p.prenom, r.nom;


-- contrôles de cohérence (doit être vide)
CREATE OR REPLACE VIEW v_controle AS
SELECT 'équipage sans 2 concurrents' AS probleme, e.id_equipage::TEXT AS objet
FROM equipage e
LEFT JOIN compose c ON c.id_equipage = e.id_equipage
GROUP BY e.id_equipage
HAVING COUNT(c.id_personne) <> 2
UNION ALL
SELECT 'équipage sans véhicule', e.id_equipage::TEXT
FROM equipage e
WHERE NOT EXISTS (SELECT 1 FROM vehicule v WHERE v.id_equipage = e.id_equipage)
UNION ALL
SELECT 'association avec moins de 2 marques', eq.nom
FROM equipe eq
LEFT JOIN regroupe rg ON rg.id_equipe = eq.id_equipe
WHERE eq.type_equipe = 'association'
GROUP BY eq.id_equipe, eq.nom
HAVING COUNT(rg.id_marque) < 2
UNION ALL
SELECT 'étape sans pays', et.id_etape::TEXT
FROM etape et
WHERE NOT EXISTS (SELECT 1 FROM traverse t WHERE t.id_etape = et.id_etape)
UNION ALL
SELECT 'numéros d''étape non consécutifs', r.nom || ' ' || r.annee
FROM rallye r
JOIN etape et ON et.id_rallye = r.id_rallye
GROUP BY r.id_rallye, r.nom, r.annee
HAVING MAX(et.numero) <> COUNT(*);
