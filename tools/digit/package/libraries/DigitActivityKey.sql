-- The campaign activities, as transform.py's Protocols collects them: one
-- per project type, delivery number and product variant. They are listed
-- first by the project types in mdms_project_type.ndjson, in file order,
-- and then by each root project's own copy of its project type, the roots
-- in order of id; within one, by cycle, delivery, dose criterion and
-- product variant as listed. A root project's activity is filed under its
-- project type (DigitProject.protocol_line).
--
-- An activity takes its quantity and wait from the first entry that lists
-- it, its strategy from the first that gives one, and the dose criteria of
-- all, each once, in the order first listed. A delivery without a number,
-- or numbered 0, is delivery 1 (transform.py: dl.get("id") or 1).
--
-- The views give each dose criterion as JSON (criterion), and its
-- ProductVariants are read from it here: the view engine cannot read an
-- element whose name starts with a capital letter (see the README).
WITH type_variant AS (
  SELECT d.*, u.v.productVariantId AS product_variant_id, u.v.quantity AS quantity, u.n AS variant_index
  FROM type_dose AS d,
       unnest(from_json(d.criterion, '{"ProductVariants": [{"productVariantId": "VARCHAR", "quantity": "DOUBLE"}]}').ProductVariants)
         WITH ORDINALITY AS u(v, n)
),
project_variant AS (
  SELECT d.*, u.v.productVariantId AS product_variant_id, u.v.quantity AS quantity, u.n AS variant_index
  FROM project_dose AS d,
       unnest(from_json(d.criterion, '{"ProductVariants": [{"productVariantId": "VARCHAR", "quantity": "DOUBLE"}]}').ProductVariants)
         WITH ORDINALITY AS u(v, n)
),
entry AS (
  SELECT 0 AS source, d.line AS source_order, d.cycle_index, d.delivery_index, d.criterion_index,
         d.variant_index, d.line AS protocol_line, d.delivery_id, d.strategy, d.wait_days,
         d.condition, d.product_variant_id, d.quantity
  FROM type_variant AS d
  UNION ALL
  SELECT 1, dense_rank() OVER (ORDER BY p.id), d.cycle_index, d.delivery_index, d.criterion_index,
         d.variant_index, p.protocol_line, d.delivery_id, d.strategy, d.wait_days,
         d.condition, d.product_variant_id, d.quantity
  FROM project_variant AS d
  JOIN project AS p ON p.id = d.project_id
  WHERE p.id = p.root_id AND p.protocol_line IS NOT NULL
),
keyed AS (
  SELECT e.*, t.protocol_id, t.code,
         CASE WHEN coalesce(e.delivery_id, 0) = 0 THEN 1 ELSE e.delivery_id END AS delivery,
         row_number() OVER (ORDER BY e.source, e.source_order, e.cycle_index, e.delivery_index,
                                     e.criterion_index, e.variant_index) AS position
  FROM entry AS e
  JOIN project_type AS t ON t.line = e.protocol_line
),
conditions AS (
  SELECT protocol_id, delivery, product_variant_id, condition, min(position) AS first_position
  FROM keyed
  WHERE coalesce(condition, '') <> ''
  GROUP BY ALL
),
activity AS (
  SELECT protocol_id, delivery, product_variant_id,
         arg_min(code, position) AS code,
         min(position) AS position,
         arg_min_null(quantity, position) AS quantity,
         arg_min_null(wait_days, position) AS wait_days,
         arg_min(strategy, position) FILTER (WHERE coalesce(strategy, '') <> '') AS strategy
  FROM keyed
  GROUP BY ALL
)
SELECT a.protocol_id, a.code, a.delivery, a.product_variant_id, a.position,
       'dgt-' || regexp_replace(a.code || '-d' || a.delivery || '-' || coalesce(a.product_variant_id, 'None'),
                                '[^A-Za-z0-9.-]', '-', 'g') AS activity_id,
       a.quantity, a.wait_days, a.strategy,
       (SELECT list(c.condition ORDER BY c.first_position) FROM conditions AS c
        WHERE c.protocol_id = a.protocol_id AND c.delivery = a.delivery
          AND c.product_variant_id IS NOT DISTINCT FROM a.product_variant_id) AS conditions
FROM activity AS a
ORDER BY a.position
