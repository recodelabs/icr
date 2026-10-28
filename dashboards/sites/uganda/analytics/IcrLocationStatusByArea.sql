-- Location status observations with their place in the location hierarchy: each IcrLocationStatus
-- row with the location_id Location's name, admin level, admin names and codes, country and path
-- from LocationHierarchy. Rows whose Location is not in the hierarchy are kept, with those columns
-- empty.
SELECT v.observation_id,
       v.location_id,
       v.property,
       v.status,
       v.effective,
       v.performer,
       v.method,
       v.evidence,
       v.figure_label,
       v.figure_value,
       v.figure_unit,
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
FROM location_status AS v
LEFT JOIN hierarchy AS h ON h.id = v.location_id
