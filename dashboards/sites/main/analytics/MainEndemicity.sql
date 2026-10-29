-- Endemicity assertions (IcrLocationStatus) for the NTD page: every assertion with its LGA and
-- state names, and is_current, true for the newest one per LGA and property. Read through
-- src/data/endemicity.parquet.sh.
-- admin_level is cast to INTEGER, the type the page had from the locations table.
SELECT s.observation_id, s.location_id, s.location_name, s.admin1_name AS state,
       CAST(s.admin_level AS INTEGER) AS admin_level,
       s.property,
       regexp_replace(s.property, '-endemicity$', '') AS disease,
       s.status, s.effective, year(s.effective) AS effective_year,
       s.performer, s.method, s.evidence,
       s.figure_label, s.figure_value, s.figure_unit,
       s.country,
       row_number() OVER (PARTITION BY s.location_id, s.property ORDER BY s.effective DESC) = 1 AS is_current
FROM location_status AS s
ORDER BY s.property, s.admin1_name, s.location_name, s.effective
