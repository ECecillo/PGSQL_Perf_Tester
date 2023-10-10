EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
WITH Doublons AS (
    SELECT
        nomprenom,
        datenaiss,
        lieunaiss,
        commnaiss,
        CASE
            WHEN SUBSTRING(lieudeces, 1, 1) = '9' THEN SUBSTRING(lieudeces, 1, 3)
            ELSE SUBSTRING(lieudeces, 1, 2)
        END AS code_departement
    FROM personne_insee
    GROUP BY
        nomprenom,
        datenaiss,
        lieunaiss,
        commnaiss,
        CASE
            WHEN SUBSTRING(lieudeces, 1, 1) = '9' THEN SUBSTRING(lieudeces, 1, 3)
            ELSE SUBSTRING(lieudeces, 1, 2)
        END
    HAVING COUNT(*) > 1
)
SELECT
    dep.nom AS departement,
    COUNT(*) AS nb_doublons
FROM Doublons d
JOIN departement dep ON d.code_departement = dep.dep
GROUP BY dep.nom
ORDER BY nb_doublons DESC, dep.nom ASC;
