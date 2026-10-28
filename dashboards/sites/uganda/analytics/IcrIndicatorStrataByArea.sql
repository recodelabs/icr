-- Indicator strata with their place in the location hierarchy: each IcrIndicatorStrata row with
-- the location_id Location's name, admin level, admin names and codes, country and path from
-- LocationHierarchy. Rows whose Location is not in the hierarchy are kept, with those columns
-- empty.
SELECT v.report_id,
       v.measure,
       v.location_id,
       v.period,
       v.dimension,
       v.dimension_name,
       v.option,
       v.option_name,
       v.numerator,
       v.denominator,
       v.count,
       v.score,
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
FROM strata AS v
LEFT JOIN hierarchy AS h ON h.id = v.location_id
