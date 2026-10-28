-- Target populations with their place in the location hierarchy: each IcrTargetPopulation row with
-- the location_id Location's name, admin level, admin names and codes, country and path from
-- LocationHierarchy. Rows whose Location is not in the hierarchy are kept, with those columns
-- empty.
SELECT v.group_id,
       v.name,
       v.quantity,
       v.location_id,
       v.age_low,
       v.age_high,
       v.age_unit,
       v.source,
       v.estimate_date,
       v.is_planning,
       v.denominator_type,
       v.is_calculated,
       v.travel_time,
       v.code,
       v.code_text,
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
FROM target_population AS v
LEFT JOIN hierarchy AS h ON h.id = v.location_id
