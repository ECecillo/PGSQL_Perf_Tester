EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
WITH Personnes AS (
  SELECT
    nomprenom,
    SUBSTRING(lieunaiss FROM 1 FOR 2) AS dep_naissance,
    (TO_DATE(datedeces, 'YYYYMMDD') - TO_DATE(datenaiss, 'YYYYMMDD')) AS duree_vie
  FROM
    (
      SELECT nomprenom, datenaiss, lieunaiss, datedeces, lieudeces, COUNT(*) as nbD
      FROM personne_insee P
      GROUP BY nomprenom, datenaiss, lieunaiss, datedeces, lieudeces
    ) t
  WHERE
    is_valid_date(datenaiss) AND is_valid_date(datedeces)
)
, DuréeMoyenne AS (
  SELECT
    dep_naissance,
    FLOOR(AVG(duree_vie) / 365.25) AS années,
    FLOOR((AVG(duree_vie) - (FLOOR(AVG(duree_vie) / 365.25) * 365.25)) / 30.44) AS mois,
    ROUND(AVG(duree_vie) - (FLOOR(AVG(duree_vie) / 365.25) * 365.25) - (FLOOR((AVG(duree_vie) - (FLOOR(AVG(duree_vie) / 365.25) * 365.25)) / 30.44) * 30.44)) AS jours
  FROM
    Personnes
  GROUP BY
    dep_naissance
)
SELECT
  dep_naissance,
  COUNT(*) AS nb,
  années || ' years ' || mois || ' mons ' || jours || ' days' AS age_moy
FROM
  DuréeMoyenne
JOIN
  Personnes USING (dep_naissance)
GROUP BY
  dep_naissance, années, mois, jours
ORDER BY
  age_moy DESC;
