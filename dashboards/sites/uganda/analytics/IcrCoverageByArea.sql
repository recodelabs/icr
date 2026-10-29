-- Coverage reports with their place in the location hierarchy: each IcrCoverage row with the
-- location_id Location's name, admin level, admin names and codes, country and path from
-- LocationHierarchy. Rows whose Location is not in the hierarchy are kept, with those columns
-- empty.
SELECT v.report_id,
       v.campaign_id,
       v.location_id,
       v.measure,
       v.source,
       v.lineage,
       v.denominator_type,
       v.status,
       v.period_start,
       v.period_end,
       v.reported,
       v.numerator,
       v.denominator,
       v.score,
       v.ci_low,
       v.ci_high,
       v.sample_design,
       v.reporter,
       v.activity,
       h.name AS location_name,
       h.admin_level,
       h.admin0_name,
       h.admin1_name,
       h.admin2_name,
       h.admin3_name,
       h.admin4_name,
       h.admin0_code,
       h.admin1_code,
       h.admin2_code,
       h.admin3_code,
       h.admin4_code,
       h.country,
       h.path
FROM coverage AS v
LEFT JOIN hierarchy AS h ON h.id = v.location_id
