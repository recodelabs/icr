-- DHIS2 indicator values (IcrIndicatorValue) joined to the indicator catalogue (IcrIndicator) and
-- the administrative units, one row per indicator, place and period. value is the figure as
-- DHIS2 shows it (score times factor). Read by the indicators page through
-- src/data/indicator_values.parquet.sh.
-- The name, admin_level and admin1_name come from LocationHierarchy for administrative units
-- only; a value for a facility keeps the view's location_name and has no level. country is the
-- view table's own (its partition column). admin_level is cast to INTEGER, the type the page had
-- from the locations table. The SQL is DuckDB's (regexp_matches).
WITH l AS (SELECT id, name, CAST(admin_level AS INTEGER) AS admin_level, admin1_name FROM hierarchy WHERE is_admin)
SELECT i.measure_id AS indicator_id, i.title AS indicator, i.topic, COALESCE(i.factor, 1) AS factor,
       i.indicator_type, i.annualized, i.source,
       v.location_id, COALESCE(l.name, v.location_name) AS location_name, l.admin_level, l.admin1_name, v.country,
       v.period,
       CASE WHEN regexp_matches(v.period, '^[0-9]{4}$') THEN 'Yearly'
            WHEN regexp_matches(v.period, '^[0-9]{6}$') THEN 'Monthly'
            WHEN regexp_matches(v.period, '^[0-9]{4}Q[1-4]$') THEN 'Quarterly'
            ELSE 'Other' END AS period_type,
       v.period_start, v.period_end, v.numerator, v.denominator, v.count, v.score,
       v.score * COALESCE(i.factor, 1) AS value, v.reported
FROM indicator_value AS v
JOIN indicator AS i ON i.url = v.measure
LEFT JOIN l ON l.id = v.location_id
ORDER BY indicator, admin_level, location_name, period_start
