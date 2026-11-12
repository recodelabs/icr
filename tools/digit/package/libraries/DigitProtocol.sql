-- The DIGIT project types as DIGITProtocolRow records (the columns are
-- named as its elements), in the order of mdms_project_type.ndjson, as
-- transform.py's Protocols.write makes the PlanDefinitions.
--
-- The actions are the project type's activities (DigitActivityKey), sorted
-- by delivery and product variant id, numbered d<delivery>-<n> with n
-- counting all the actions of the project type. An action after the first
-- delivery is related to the first action of the delivery before it when
-- its activity has a wait in days.
--
-- A project type with validMinAge or validMaxAge gets an eligible
-- population Group with that age band, in months.
WITH act AS (
  SELECT a.*, coalesce(v.label, 'DIGIT product variant ' || coalesce(a.product_variant_id, 'None')) AS label,
         row_number() OVER (PARTITION BY a.protocol_id ORDER BY a.delivery, coalesce(a.product_variant_id, '')) AS n
  FROM activity AS a
  LEFT JOIN product_variant AS v ON v.product_variant_id = a.product_variant_id
),
numbered AS (
  SELECT *, 'd' || delivery || '-' || n AS action_id FROM act
),
first_of AS (
  SELECT protocol_id, delivery, arg_min(action_id, n) AS action_id FROM numbered GROUP BY ALL
),
action AS (
  SELECT a.protocol_id,
         list(struct_pack(
           id := a.action_id,
           title := 'Delivery ' || a.delivery || ': ' || a.label,
           definition := 'https://icr.healthcampaigns.org/ActivityDefinition/' || a.activity_id,
           "condition" := CASE WHEN len(a.conditions) > 0
                               THEN array_to_string(list_transform(a.conditions, lambda c: '(' || c || ')'), ' or ') END,
           after := CASE WHEN coalesce(a.wait_days, 0) <> 0 THEN f.action_id END,
           waitDays := CASE WHEN f.action_id IS NOT NULL AND coalesce(a.wait_days, 0) <> 0 THEN a.wait_days END)
           ORDER BY a.n) AS action
  FROM numbered AS a
  LEFT JOIN first_of AS f ON f.protocol_id = a.protocol_id AND f.delivery = a.delivery - 1
  GROUP BY a.protocol_id
)
SELECT t.protocol_id AS "id", t.type_id AS "typeId", t.code AS "code",
       regexp_replace('DigitDemo_' || replace(t.code, '-', '_'), '[^A-Za-z0-9_]', '', 'g') AS "name",
       coalesce(nullif(t.name, ''), t.code) || ' (' || t.code || ')' AS "title",
       CASE WHEN t.is_active THEN 'active' ELSE 'retired' END AS "status",
       t.campaign_type AS "campaignType", t.campaign_type_display AS "campaignDisplay",
       nullif(concat_ws(' ',
         CASE WHEN coalesce(t.beneficiary_type, '') <> '' THEN 'Beneficiary type: ' || t.beneficiary_type || '.' END,
         CASE WHEN coalesce(t.observation_strategy, '') <> '' THEN 'Observation strategy: ' || t.observation_strategy || '.' END,
         CASE WHEN len(from_json(t.eligibility_criteria, '["VARCHAR"]')) > 0
              THEN 'Eligibility: ' || array_to_string(from_json(t.eligibility_criteria, '["VARCHAR"]'), ' ') END), '') AS "description",
       CASE WHEN t.valid_min_age IS NOT NULL OR t.valid_max_age IS NOT NULL
            THEN t.protocol_id || '-eligible' END AS "eligibleGroup",
       t.valid_min_age AS "minAge", t.valid_max_age AS "maxAge",
       a.action AS "action"
FROM project_type AS t
LEFT JOIN action AS a ON a.protocol_id = t.protocol_id
ORDER BY t.line
