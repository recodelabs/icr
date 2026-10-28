-- Indicator values with their place in the location hierarchy: each IcrIndicatorValue row with the
-- location_id Location's admin level, admin names and codes, country and path from
-- LocationHierarchy. Rows whose Location is not in the hierarchy are kept, with those columns
-- empty. The view has its own location_name, so the Location's name is not added again.
SELECT v.report_id,
       v.measure,
       v.location_id,
       v.location_name,
       v.period,
       v.period_start,
       v.period_end,
       v.numerator,
       v.denominator,
       v.count,
       v.score,
       v.reported,
       v.source,
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
FROM indicator_value AS v
LEFT JOIN hierarchy AS h ON h.id = v.location_id
