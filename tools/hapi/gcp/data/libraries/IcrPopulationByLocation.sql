WITH tp AS (
  SELECT v.location_id, h.name AS location_name, CAST(h.admin_level AS INTEGER) AS admin_level,
         h.admin1_name, h.admin2_name, h.country, v.source, v.quantity, v.estimate_date, v.is_calculated
  FROM target_population AS v
  JOIN hierarchy AS h ON h.id = v.location_id
  WHERE v.denominator_type = 'total-population' AND h.is_admin
    AND v.source IN ('worldpop', 'census-projection')
),
w AS (SELECT location_id, estimate_date, quantity AS worldpop, is_calculated AS worldpop_calculated FROM tp WHERE source = 'worldpop'),
c AS (SELECT location_id, estimate_date, quantity AS census FROM tp WHERE source = 'census-projection'),
keys AS (SELECT DISTINCT location_id, location_name, admin_level, admin1_name, admin2_name, country, estimate_date FROM tp)
SELECT k.country,
       k.location_id,
       k.location_name,
       k.admin_level,
       k.admin1_name AS state,
       k.admin2_name AS lga,
       year(k.estimate_date) AS year,
       k.estimate_date,
       c.census,
       w.worldpop,
       w.worldpop_calculated,
       w.worldpop - c.census AS difference,
       round((w.worldpop - c.census) / CAST(c.census AS DOUBLE), 4) AS difference_share
FROM keys AS k
LEFT JOIN w ON w.location_id = k.location_id AND w.estimate_date = k.estimate_date
LEFT JOIN c ON c.location_id = k.location_id AND c.estimate_date = k.estimate_date
ORDER BY k.country, year, k.admin_level, state, lga
