-- One row per administrative unit (country, regions, districts and cities): the Ministry of
-- Health's total population 2026 and catch population 2025 (from the targets workbook) beside
-- WorldPop's 2026 total, read from the target-population Groups by their ids.
-- admin_level is cast to INTEGER, the type the pages had from the locations table
-- (LocationHierarchy gives a BIGINT, which JavaScript reads as a BigInt).
SELECT h.id AS location_id, h.name AS location_name,
       CAST(h.admin_level AS INTEGER) AS admin_level,
       COALESCE(h.admin1_name, h.name) AS region,
       MAX(CASE WHEN g.group_id = 'ichd-2026-10-population-2026-' || h.id THEN g.quantity END) AS moh_2026,
       MAX(CASE WHEN g.group_id = 'ichd-2026-10-catch-population-2025-' || h.id THEN g.quantity END) AS catch_2025,
       MAX(CASE WHEN g.group_id = 'pop-worldpop-2026-' || h.id THEN g.quantity END) AS worldpop_2026
FROM hierarchy AS h
LEFT JOIN target_population AS g ON g.location_id = h.id
WHERE h.is_admin
GROUP BY h.id, h.name, h.admin_level, h.admin1_name
ORDER BY h.admin_level, region, location_name
