-- Triggers et fonctions


-- 2 concurrents max par équipage, et un seul équipage par rallye pour un concurrent
CREATE OR REPLACE FUNCTION verif_compose() RETURNS TRIGGER AS $$
DECLARE
    nb       INTEGER;
    v_rallye INTEGER;
    v_numero INTEGER;
    v_nom    VARCHAR(101);
BEGIN
    SELECT id_rallye, numero INTO v_rallye, v_numero FROM equipage WHERE id_equipage = NEW.id_equipage;
    SELECT prenom || ' ' || nom INTO v_nom FROM personne WHERE id_personne = NEW.id_personne;

    SELECT COUNT(*) INTO nb FROM compose
    WHERE id_equipage = NEW.id_equipage
      AND id_personne <> NEW.id_personne
      AND (TG_OP = 'INSERT' OR id_personne <> OLD.id_personne);

    IF nb >= 2 THEN
        RAISE EXCEPTION 'L''équipage n°% a déjà 2 concurrents', v_numero;
    END IF;

    IF EXISTS (
        SELECT 1 FROM compose c
        JOIN equipage e ON e.id_equipage = c.id_equipage
        WHERE c.id_personne = NEW.id_personne
          AND e.id_rallye = v_rallye
          AND c.id_equipage <> NEW.id_equipage
    ) THEN
        RAISE EXCEPTION '% est déjà dans un autre équipage de ce rallye', v_nom;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_compose ON compose;
CREATE TRIGGER trg_compose BEFORE INSERT OR UPDATE ON compose
FOR EACH ROW EXECUTE FUNCTION verif_compose();


-- équipage et étape du même rallye + disqualification si arrivée après la fermeture
CREATE OR REPLACE FUNCTION verif_resultat() RETURNS TRIGGER AS $$
DECLARE
    v_rallye_equipage INTEGER;
    v_rallye_etape    INTEGER;
    v_type            VARCHAR(10);
    v_fermeture       TIME;
BEGIN
    SELECT id_rallye INTO v_rallye_equipage FROM equipage WHERE id_equipage = NEW.id_equipage;

    SELECT id_rallye, type_etape, heure_fermeture
    INTO v_rallye_etape, v_type, v_fermeture
    FROM etape WHERE id_etape = NEW.id_etape;

    IF v_rallye_equipage <> v_rallye_etape THEN
        RAISE EXCEPTION 'L''équipage et l''étape ne font pas partie du même rallye';
    END IF;

    IF v_type = 'speciale' AND NEW.heure_arrivee > v_fermeture THEN
        NEW.disqualifie := TRUE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_resultat ON resultat;
CREATE TRIGGER trg_resultat BEFORE INSERT OR UPDATE ON resultat
FOR EACH ROW EXECUTE FUNCTION verif_resultat();


-- marque du véhicule cohérente avec l'équipe + numéro de course unique dans le rallye
CREATE OR REPLACE FUNCTION verif_vehicule() RETURNS TRIGGER AS $$
DECLARE
    v_equipe equipe%ROWTYPE;
    v_rallye INTEGER;
BEGIN
    SELECT eq.* INTO v_equipe
    FROM equipe eq JOIN equipage e ON e.id_equipe = eq.id_equipe
    WHERE e.id_equipage = NEW.id_equipage;

    IF v_equipe.type_equipe = 'officielle' AND NEW.id_marque <> v_equipe.id_marque THEN
        RAISE EXCEPTION 'L''équipe officielle % ne peut courir qu''avec sa marque', v_equipe.nom;
    END IF;

    IF v_equipe.type_equipe = 'association' AND NOT EXISTS (
        SELECT 1 FROM regroupe WHERE id_equipe = v_equipe.id_equipe AND id_marque = NEW.id_marque
    ) THEN
        RAISE EXCEPTION 'La marque du véhicule ne fait pas partie de l''association %', v_equipe.nom;
    END IF;

    SELECT id_rallye INTO v_rallye FROM equipage WHERE id_equipage = NEW.id_equipage;

    IF EXISTS (
        SELECT 1 FROM vehicule v
        JOIN equipage e ON e.id_equipage = v.id_equipage
        WHERE e.id_rallye = v_rallye
          AND v.num_course = NEW.num_course
          AND v.id_vehicule <> NEW.id_vehicule
    ) THEN
        RAISE EXCEPTION 'Le numéro de course % est déjà pris dans ce rallye', NEW.num_course;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_vehicule ON vehicule;
CREATE TRIGGER trg_vehicule BEFORE INSERT OR UPDATE ON vehicule
FOR EACH ROW EXECUTE FUNCTION verif_vehicule();


-- seules les associations regroupent des marques
CREATE OR REPLACE FUNCTION verif_regroupe() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT type_equipe FROM equipe WHERE id_equipe = NEW.id_equipe) <> 'association' THEN
        RAISE EXCEPTION 'Seule une équipe de type association peut regrouper des marques';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_regroupe ON regroupe;
CREATE TRIGGER trg_regroupe BEFORE INSERT OR UPDATE ON regroupe
FOR EACH ROW EXECUTE FUNCTION verif_regroupe();


-- nombre de participations d'un concurrent (à un rallye donné, ou à tous si NULL)
CREATE OR REPLACE FUNCTION nb_participations(p_id_personne INTEGER, p_nom_rallye VARCHAR DEFAULT NULL)
RETURNS INTEGER AS $$
    SELECT COUNT(*)::INTEGER
    FROM compose c
    JOIN equipage e ON e.id_equipage = c.id_equipage
    JOIN rallye r ON r.id_rallye = e.id_rallye
    WHERE c.id_personne = p_id_personne
      AND (p_nom_rallye IS NULL OR r.nom = p_nom_rallye);
$$ LANGUAGE sql STABLE;
