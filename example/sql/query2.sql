EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
WITH SS1 AS (
  SELECT EXTRACT(YEAR FROM decades_series) as decades_start,
         EXTRACT(YEAR FROM (decades_series + '1 decade'::interval)) as decades_end
  FROM (
    SELECT generate_series('1970-01-01'::date, CURRENT_DATE, '1 decade'::interval) AS decades_series
  ) t
),
SS2 AS (
  SELECT
    split_part(nomprenom, '*', 1) AS nom,
    CASE WHEN is_valid_date(datenaiss) THEN EXTRACT(YEAR FROM TO_DATE(datenaiss, 'YYYYMMDD'))::integer END AS annee_naissance, CASE WHEN is_valid_date(datedeces) THEN EXTRACT(YEAR FROM TO_DATE(datedeces, 'YYYYMMDD'))::integer END AS annee_deces FROM personne_insee P
  WHERE
    LENGTH(nomprenom) <= 80 AND
    is_valid_date(datenaiss) AND
    is_valid_date(datedeces) AND
    (CASE WHEN is_valid_date(datenaiss) AND is_valid_date(datedeces) THEN TO_DATE(datenaiss, 'YYYYMMDD') <= TO_DATE(datedeces, 'YYYYMMDD') ELSE FALSE END)
  GROUP BY nomprenom, datenaiss, lieunaiss, datedeces, lieudeces
),
RankedNames AS (
  SELECT
    decades_start AS decades,
    SS2.nom,
    COUNT(*) AS occurrences,
    ROW_NUMBER() OVER (PARTITION BY SS1.decades_start ORDER BY COUNT(*) DESC) AS rank
  FROM SS1
  JOIN SS2 ON
    SS2.annee_naissance BETWEEN SS1.decades_start AND SS1.decades_end
    OR SS2.annee_deces BETWEEN SS1.decades_start AND SS1.decades_end
    OR SS1.decades_start BETWEEN SS2.annee_naissance AND SS2.annee_deces
    OR SS1.decades_end BETWEEN SS2.annee_naissance AND SS2.annee_deces
  GROUP BY SS1.decades_start, SS2.nom
)
SELECT
  decades,
  STRING_AGG(rank || '. ' || nom || ' (' || occurrences || ')', ' ; ') AS classement
FROM RankedNames
WHERE rank <= 10
GROUP BY decades
ORDER BY decades;
