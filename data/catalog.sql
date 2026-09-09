-- DuckDB catalog over the parquet hub. Run from this directory:
--   cd data && duckdb -init catalog.sql
-- Paths are relative so the same file works against a bucket mirror
-- (replace the globs with s3:// or https:// URLs, or set the working directory).
-- Globs start at country=*/ so the Portolan metadata beside the data
-- (collection.json, items.parquet) is never read as part of a table.

CREATE OR REPLACE VIEW locations AS
  SELECT * FROM read_parquet('parquet/locations/country=*/**/*.parquet', hive_partitioning = true, union_by_name = true);

CREATE OR REPLACE VIEW campaign_calendar AS
  SELECT * FROM read_parquet('parquet/campaign_calendar/country=*/**/*.parquet', hive_partitioning = true, union_by_name = true);

CREATE OR REPLACE VIEW target_population AS
  SELECT * FROM read_parquet('parquet/target_population/country=*/**/*.parquet', hive_partitioning = true, union_by_name = true);

CREATE OR REPLACE VIEW coverage AS
  SELECT * FROM read_parquet('parquet/coverage/country=*/**/*.parquet', hive_partitioning = true, union_by_name = true);

CREATE OR REPLACE VIEW coverage_strata AS
  SELECT * FROM read_parquet('parquet/coverage_strata/country=*/**/*.parquet', hive_partitioning = true, union_by_name = true);

CREATE OR REPLACE VIEW location_status AS
  SELECT * FROM read_parquet('parquet/location_status/country=*/**/*.parquet', hive_partitioning = true, union_by_name = true);

-- Convenience: the CURRENT classification per location × property (newest assertion wins).
CREATE OR REPLACE VIEW location_status_current AS
  SELECT * FROM location_status
  QUALIFY row_number() OVER (PARTITION BY location_id, property ORDER BY effective DESC) = 1;

-- Convenience: LGA-level calendar rows with their state and LGA names.
CREATE OR REPLACE VIEW campaign_calendar_lga AS
  SELECT c.*, l.name AS lga, l.admin1_name AS state
  FROM campaign_calendar c
  JOIN locations l ON l.id = c.location_id
  WHERE l.type = 'admin-unit' AND l.admin_level = 2;

-- Convenience: two total-population denominators for the same admin unit and year, side by side
-- (WorldPop grid summed over the boundary vs the census projection), with the delta. Feeds the
-- Campaign Targeting dashboard.
CREATE OR REPLACE VIEW target_population_worldpop_vs_census AS
  SELECT w.location_id, l.name AS location_name, l.admin_level, l.admin1_name AS state, w.estimate_date,
         w.quantity AS worldpop, c.quantity AS census_projection,
         w.quantity - c.quantity AS delta,
         (w.quantity - c.quantity) / c.quantity::DOUBLE AS delta_share
  FROM target_population w
  JOIN target_population c
    ON c.location_id = w.location_id AND c.estimate_date = w.estimate_date
   AND c.source = 'census-projection' AND c.denominator_type = 'total-population'
  JOIN locations l ON l.id = w.location_id
  WHERE w.source = 'worldpop' AND w.denominator_type = 'total-population';

-- Convenience: administrative (reconciled) vs survey coverage for the same campaign, side by side.
CREATE OR REPLACE VIEW coverage_admin_vs_survey AS
  SELECT a.campaign_id, a.location_id, a.score AS admin_coverage, s.score AS survey_coverage, s.ci_low, s.ci_high,
         a.score BETWEEN s.ci_low AND s.ci_high AS admin_within_survey_ci
  FROM coverage a
  JOIN coverage s ON s.campaign_id = a.campaign_id AND s.source = 'survey'
  WHERE a.source = 'administrative' AND a.lineage = 'reconciled';
