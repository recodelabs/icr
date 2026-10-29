-- The indicator catalogue (IcrIndicator) for the indicators page: one row per Measure with a
-- factor, which the DHIS2 indicators have. Read through src/data/indicator_catalog.parquet.sh.
SELECT measure_id AS indicator_id, title AS indicator, topic, scoring, COALESCE(factor, 1) AS factor,
       indicator_type, annualized, source, publisher, description, numerator_description, denominator_description
FROM indicator
WHERE factor IS NOT NULL
ORDER BY topic, title
