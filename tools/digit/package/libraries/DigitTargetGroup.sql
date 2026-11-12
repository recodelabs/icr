-- The target populations of the DIGIT projects, as transform.py's
-- write_targets makes them: for each project with a root project, in the
-- order of project.ndjson, each target that is not deleted, and for each
-- target its targetNo ("targeted", the at-risk population) and its totalNo
-- ("in total"), each when above 0. A project that is not a root and whose
-- boundary was not exported has no targets written.
--
-- The Group id is dgt-, the target id and -target or -baseline. When an id
-- was already used (DIGIT copies a target onto several projects), the
-- project id goes into the id too, as transform.py does; that id is longer
-- than 64 characters, so it is shortened with a hash as fhirutil.fid does:
-- the first characters, a dash, the first 12 hex digits of the SHA-1 of
-- "<target id>-<project id>|<suffix>", then the suffix.
WITH t AS (
  SELECT p.line, p.id AS project_id, p.name AS project_name, p.boundary,
         p.id = p.root_id AS is_root, b.code IS NOT NULL AS boundary_exported,
         g.target_index, g.id AS target_id,
         coalesce(nullif(g.beneficiary_type, ''), 'INDIVIDUAL') AS beneficiary_type,
         g.target_no, g.total_no
  FROM project AS p
  JOIN target AS g ON g.project_id = p.id
  LEFT JOIN boundary AS b ON b.code = p.boundary
  WHERE p.root_id IS NOT NULL
    AND (b.code IS NOT NULL OR p.id = p.root_id)
    AND NOT coalesce(g.is_deleted, false)
),
n AS (
  SELECT t.*, f.field_index, f.denominator_type, f.suffix, f.count_label,
         CASE f.field_index WHEN 1 THEN t.target_no ELSE t.total_no END AS number
  FROM t,
       (VALUES (1, 'at-risk', '-target', 'targeted'),
               (2, 'total-population', '-baseline', 'in total')) AS f(field_index, denominator_type, suffix, count_label)
),
counted AS (
  SELECT *, 'dgt-' || regexp_replace(target_id, '[^A-Za-z0-9.-]', '-', 'g') || suffix AS plain_id
  FROM n WHERE number > 0
),
numbered AS (
  SELECT *, row_number() OVER (PARTITION BY plain_id ORDER BY line, target_index, field_index) AS same_id
  FROM counted
),
alt AS (
  SELECT *, regexp_replace(target_id || '-' || project_id, '[^A-Za-z0-9.-]', '-', 'g') AS alt_raw
  FROM numbered
)
SELECT line, target_index, field_index, project_id, project_name, is_root, beneficiary_type,
       CASE WHEN same_id = 1 THEN plain_id
            WHEN length('dgt-' || alt_raw || suffix) <= 64 THEN 'dgt-' || alt_raw || suffix
            ELSE 'dgt-' || left(alt_raw, 64 - 4 - length(suffix) - 13) || '-'
                 || left(sha1(target_id || '-' || project_id || '|' || suffix), 12) || suffix
       END AS group_id,
       target_id, denominator_type, count_label,
       CASE WHEN beneficiary_type = 'HOUSEHOLD' THEN 'household' ELSE 'person' END AS unit,
       nullif(boundary, '') AS place,
       CASE WHEN boundary_exported THEN 'dgt-' || regexp_replace(boundary, '[^A-Za-z0-9.-]', '-', 'g') END AS geography,
       CAST(trunc(number) AS BIGINT) AS quantity
FROM alt
ORDER BY line, target_index, field_index
