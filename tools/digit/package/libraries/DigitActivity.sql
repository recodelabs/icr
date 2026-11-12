-- The campaign activities as DIGITActivityRow records (the columns are
-- named as its elements), in the order transform.py writes them.
--
-- The product is read from the catalogue (DigitProductVariant): its label,
-- kind (which gives the verb), standard code and unit. A variant not in the
-- catalogue is "DIGIT product variant <id>", delivered, counted in units.
--
-- Two project types with the same code give their activities the same id;
-- transform.py writes the first and refuses the others, and so does this.
WITH a AS (
  SELECT a.*, t.is_active, t.task_procedure, t.campaign_type, t.campaign_type_display,
         coalesce(v.label, 'DIGIT product variant ' || coalesce(a.product_variant_id, 'None')) AS label,
         v.kind, v.standard_system, v.standard_code, v.standard_display,
         coalesce(v.unit, 'units') AS unit, coalesce(v.unit_code, '1') AS unit_code,
         CASE v.kind WHEN 'vaccine' THEN 'Vaccinate' WHEN 'drug' THEN 'Treat'
                     WHEN 'commodity' THEN 'Distribute' ELSE 'Deliver' END AS verb
  FROM activity AS a
  JOIN project_type AS t ON t.protocol_id = a.protocol_id
  LEFT JOIN product_variant AS v ON v.product_variant_id = a.product_variant_id
  QUALIFY row_number() OVER (PARTITION BY a.activity_id ORDER BY a.position) = 1
)
SELECT activity_id AS "id",
       product_variant_id AS "productVariantId",
       left(regexp_replace('DigitDemo_' || replace(activity_id, '-', '_'), '[^A-Za-z0-9_]', '', 'g'), 254) AS "name",
       verb || ': ' || label || ', delivery ' || delivery || ' (' || code || ')' AS "title",
       CASE WHEN is_active THEN 'active' ELSE 'retired' END AS "status",
       verb AS "verb",
       campaign_type AS "campaignType", campaign_type_display AS "campaignDisplay",
       nullif(array_to_string(from_json(task_procedure, '["VARCHAR"]'), ' '), '') AS "description",
       label AS "label",
       standard_system AS "standardSystem", standard_code AS "standardCode", standard_display AS "standardDisplay",
       quantity AS "quantity", unit AS "unit", unit_code AS "ucum",
       nullif(concat_ws(', ',
         CASE WHEN coalesce(strategy, '') <> '' THEN 'DIGIT delivery strategy ' || strategy
              || CASE WHEN strategy = 'DIRECT' THEN ' (directly observed)' ELSE '' END END,
         CASE WHEN len(conditions) > 0 THEN 'dose criteria: ' || array_to_string(conditions, '; ') END), '') AS "dosage"
FROM a
ORDER BY position
