-- DuckDB catalog over the parquet hub. Run from this directory:
--   cd data && duckdb -init catalog.sql
-- Paths are relative so the same file works against a bucket mirror
-- (replace the globs with s3:// or https:// URLs, or set the working directory).

CREATE OR REPLACE VIEW locations AS
  SELECT * FROM read_parquet('parquet/locations/**/*.parquet', hive_partitioning = true, union_by_name = true);

CREATE OR REPLACE VIEW campaign_calendar AS
  SELECT * FROM read_parquet('parquet/campaign_calendar/**/*.parquet', hive_partitioning = true, union_by_name = true);

CREATE OR REPLACE VIEW target_population AS
  SELECT * FROM read_parquet('parquet/target_population/**/*.parquet', hive_partitioning = true, union_by_name = true);

-- Convenience: LGA-level calendar rows with their state and LGA names.
CREATE OR REPLACE VIEW campaign_calendar_lga AS
  SELECT c.*, l.name AS lga, l.admin1_name AS state
  FROM campaign_calendar c
  JOIN locations l ON l.id = c.location_id
  WHERE l.type = 'admin-unit' AND l.admin_level = 2;
