-- Uganda's districts and cities as one GeoJSON FeatureCollection for
-- `fhir-pipes import location-boundaries` (see README.md here).
--
-- Overture Maps divisions (OpenStreetMap, ODbL): the 146 units at Overture's `county` level,
-- which are Uganda's districts and cities, with their region. Two changes so the units match
-- the Ministry of Health's list (Oct 2026_ICHDs_EPI Targets.xlsx):
--   * Entebbe City is not a city in that list; its area goes back into Wakiso.
--   * Lira City is missing from Overture: it is the OCHA COD-AB Lira Municipality (2020),
--     smaller than the city is today, cut out of Overture's Lira.
-- P-codes come from the COD-AB districts (2020) by name; the 10 cities and Terego have none.
--
-- Run from this folder:  duckdb -c ".read districts.sql"
-- Needs: overture/ug_division*.parquet (see README.md) and cod/uga_admin{2,3}.geojson.
LOAD spatial;
SET geometry_always_xy = true;

-- Names compared lower case, without the District/City suffix, with Overture's spellings
-- where the sources differ (Luwero/Luweero, Ssembabule/Sembabule).
CREATE MACRO norm(s) AS replace(replace(trim(regexp_replace(regexp_replace(lower(trim(s)),
  ' (district|city|municipality)$', ''), '[^a-z]+', ' ', 'g')), 'luwero', 'luweero'), 'ssembabule', 'sembabule');

CREATE TABLE ov AS
SELECT d.id AS gers, d.names.primary AS name, d.wikidata, d.region AS iso_region, a.geometry AS geom
FROM 'overture/ug_division.parquet' d JOIN 'overture/ug_division_area.parquet' a ON a.division_id = d.id
WHERE d.subtype = 'county';

CREATE TABLE regions AS
SELECT region AS iso_region, names.primary AS region_name FROM 'overture/ug_division.parquet' WHERE subtype = 'region';

CREATE TABLE cod2 AS SELECT adm2_name, adm2_pcode, norm(adm2_name) AS key FROM ST_Read('cod/uga_admin2.geojson');
CREATE TABLE lira_municipality AS
SELECT adm3_pcode, ST_SetCRS(geom, 'OGC:CRS84') AS geom FROM ST_Read('cod/uga_admin3.geojson') WHERE adm3_name = 'Lira Municipality';

-- The workbook's names, to carry as aliases where they differ.
CREATE TABLE workbook AS SELECT sheet_name, norm(sheet_name) AS key, sheet_name LIKE '% City' AS is_city
FROM read_csv('targets-names.csv');

CREATE TABLE units AS
SELECT gers, name, wikidata, iso_region, NULL AS boundary_pcode,
  CASE name
    WHEN 'Wakiso' THEN (SELECT ST_Union(ov.geom, e.geom) FROM ov e WHERE e.name = 'Entebbe City')
    WHEN 'Lira' THEN ST_Difference(ov.geom, (SELECT geom FROM lira_municipality))
    ELSE geom END AS geom,
  CASE name
    WHEN 'Wakiso' THEN 'Overture Maps 2026-10-21.0 (OpenStreetMap, ODbL), with Entebbe City merged in'
    WHEN 'Lira' THEN 'Overture Maps 2026-10-21.0 (OpenStreetMap, ODbL), without Lira City'
    ELSE 'Overture Maps 2026-10-21.0 (OpenStreetMap, ODbL)' END AS source
FROM ov WHERE name <> 'Entebbe City'
UNION ALL
SELECT NULL, 'Lira City', NULL, 'UG-N', (SELECT adm3_pcode FROM lira_municipality),
  ST_Intersection((SELECT geom FROM lira_municipality), (SELECT geom FROM ov WHERE name = 'Lira')),
  'OCHA COD-AB Uganda v01 (2020), Lira Municipality: smaller than Lira City today';

-- Every unit must match exactly one workbook row, and every row one unit.
CREATE TABLE matched AS
SELECT u.*, w.sheet_name,
  CASE WHEN u.name NOT LIKE '% City' THEN   -- a city's name would otherwise match its district's
    (SELECT adm2_pcode FROM cod2 WHERE cod2.key = norm(u.name)) END AS pcode
FROM units u LEFT JOIN workbook w
  ON (w.is_city = (u.name LIKE '% City'))
 AND w.key = norm(u.name);

SELECT count(*) AS units, count(sheet_name) AS matched_to_workbook, count(pcode) AS with_pcode,
  (SELECT count(*) FROM workbook) AS workbook_rows,
  (SELECT count(DISTINCT sheet_name) FROM matched) AS distinct_rows_matched
FROM matched;
SELECT 'unit without a workbook row' AS problem, name FROM matched WHERE sheet_name IS NULL
UNION ALL SELECT 'workbook row without a unit', sheet_name FROM workbook WHERE sheet_name NOT IN (SELECT sheet_name FROM matched WHERE sheet_name IS NOT NULL);
-- Shapes must tile the country without overlaps.
SELECT round(sum(ST_Area_Spheroid(geom)) / 1e6) AS sum_km2,
  (SELECT round(ST_Area_Spheroid(geometry) / 1e6) FROM 'overture/ug_division_area.parquet' WHERE subtype = 'country') AS country_km2
FROM matched;

COPY (
  SELECT r.region_name AS region, lower(replace(m.iso_region, 'UG-', '')) AS region_code, m.name AS district,
    nullif(concat_ws(';', CASE WHEN m.sheet_name <> m.name THEN m.sheet_name END,
                          (SELECT adm2_name FROM cod2 WHERE adm2_pcode = m.pcode AND adm2_name <> m.name)), '') AS district_aliases,
    m.pcode, m.boundary_pcode, m.gers, m.wikidata, m.source, m.sheet_name AS workbook_name, ST_Force2D(m.geom) AS geom
  FROM matched m JOIN regions r USING (iso_region)
  ORDER BY region, district
) TO 'build/districts.geojson' WITH (FORMAT GDAL, DRIVER 'GeoJSON', LAYER_CREATION_OPTIONS 'RFC7946=YES');
