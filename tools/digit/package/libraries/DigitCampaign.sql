-- The DIGIT campaigns as DIGITCampaignRow records (the columns are named as
-- its elements), as transform.py's write_campaigns makes the CarePlans: for
-- each root project with a CarePlan (DigitCampaignRoot, without a reason),
-- in order of id, one CarePlan for the campaign and, when the project's own
-- copy of its project type has more than one cycle, one per cycle, part of
-- it.
WITH campaign_row AS (
  SELECT * FROM campaign_root WHERE reason IS NULL
),
-- The activities of each campaign, from the root project's own copy of its
-- project type, its cycles in order of number: each activity once, in the
-- order first listed, with the cycles that list it.
project_variant AS (
  SELECT d.*, u.v.productVariantId AS product_variant_id, u.n AS variant_index
  FROM project_dose AS d,
       unnest(from_json(d.criterion, '{"ProductVariants": [{"productVariantId": "VARCHAR"}]}').ProductVariants)
         WITH ORDINALITY AS u(v, n)
),
listed AS (
  SELECT r.id AS root_id, a.activity_id, d.cycle_id,
         row_number() OVER (PARTITION BY r.id ORDER BY d.cycle_id, d.cycle_index, d.delivery_index,
                                                       d.criterion_index, d.variant_index) AS position
  FROM campaign_row AS r
  JOIN project_variant AS d ON d.project_id = r.id
  JOIN activity AS a
    ON a.protocol_id = r.protocol_id
   AND a.delivery = CASE WHEN coalesce(d.delivery_id, 0) = 0 THEN 1 ELSE d.delivery_id END
   AND a.product_variant_id IS NOT DISTINCT FROM d.product_variant_id
  WHERE d.cycle_id IS NOT NULL
),
campaign_activity AS (
  SELECT root_id, activity_id, min(position) AS position, list(DISTINCT cycle_id) AS cycles
  FROM listed GROUP BY ALL
),
cycles AS (
  SELECT c.project_id AS root_id, c.cycle_id, c.cycle_index,
         CAST(trunc(CASE WHEN c.start_date > 0 THEN CASE WHEN c.start_date < 1e11 THEN c.start_date * 1000 ELSE c.start_date END END) AS BIGINT) AS start_ms,
         CAST(trunc(CASE WHEN c.end_date > 0 THEN CASE WHEN c.end_date < 1e11 THEN c.end_date * 1000 ELSE c.end_date END END) AS BIGINT) AS end_ms,
         count(*) OVER (PARTITION BY c.project_id) AS cycle_count
  FROM cycle AS c
  WHERE c.cycle_id IS NOT NULL
),
plan AS (
  SELECT r.id AS root_id, 0 AS round_order, 'dgt-' || regexp_replace(r.id, '[^A-Za-z0-9.-]', '-', 'g') AS careplan_id,
         NULL::BIGINT AS round, r.title AS title, r.start_ms, r.end_ms
  FROM campaign_row AS r
  UNION ALL
  SELECT r.id, row_number() OVER (PARTITION BY r.id ORDER BY c.cycle_id, c.cycle_index),
         'dgt-' || regexp_replace(r.id, '[^A-Za-z0-9.-]', '-', 'g') || '-c' || c.cycle_id,
         c.cycle_id, r.title || ', cycle ' || c.cycle_id,
         coalesce(c.start_ms, r.start_ms), coalesce(c.end_ms, r.end_ms)
  FROM campaign_row AS r
  JOIN cycles AS c ON c.root_id = r.id AND c.cycle_count > 1
)
SELECT p.careplan_id AS "id",
       r.id AS "projectId", nullif(r.project_number, '') AS "projectNumber",
       CASE WHEN r.record_id IS NOT NULL THEN nullif(r.campaign_number, '') ELSE nullif(r.reference_id, '') END AS "campaignNumber",
       nullif(r.record_id, '') AS "campaignId",
       'https://icr.healthcampaigns.org/PlanDefinition/' || r.protocol_id AS "protocol",
       r.campaign_type AS "campaignType", r.campaign_type_display AS "campaignDisplay",
       r.status AS "status",
       CASE WHEN r.status = 'draft' THEN 'plan' ELSE 'order' END AS "intent",
       CASE r.status WHEN 'draft' THEN 'not-started' WHEN 'active' THEN 'in-progress' ELSE 'completed' END AS "detailStatus",
       p.title AS "title", nullif(r.description, '') AS "description",
       r.subject AS "subject", r.geography AS "geography",
       p.round AS "round",
       CASE WHEN p.round IS NOT NULL THEN 'dgt-' || regexp_replace(r.id, '[^A-Za-z0-9.-]', '-', 'g') END AS "partOf",
       strftime(epoch_ms(p.start_ms), '%Y-%m-%dT%H:%M:%SZ') AS "start",
       strftime(epoch_ms(p.end_ms), '%Y-%m-%dT%H:%M:%SZ') AS "end",
       (SELECT list('https://icr.healthcampaigns.org/ActivityDefinition/' || a.activity_id ORDER BY a.position)
        FROM campaign_activity AS a
        WHERE a.root_id = r.id AND (p.round IS NULL OR list_contains(a.cycles, p.round))) AS "activity"
FROM plan AS p
JOIN campaign_row AS r ON r.id = p.root_id
ORDER BY r.id, p.round_order
