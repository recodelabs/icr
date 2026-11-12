-- The DIGIT projects, one row per project, with:
--
-- root_id: the root project of the campaign the project belongs to, found
-- as transform.py's Projects.root finds it: up the parents to a project with
-- no parent; when a parent is missing from the export (or the parents go
-- round), the first id in projectHierarchy that is an exported root
-- project. A project with neither has no root and is not imported.
--
-- protocol_line: for every project, the line in mdms_project_type.ndjson of
-- its project type: the first with its projectTypeId as data.id
-- (transform.py's Protocols.for_project). transform.py then tries the
-- project's projectType as a code; the package does not read projectType
-- (see the README, "Where this differs from transform.py").
WITH RECURSIVE up AS (
  SELECT id AS project_id, id AS at_id, parent AS at_parent, [id] AS seen FROM project
  UNION ALL
  SELECT u.project_id, p.id, p.parent, list_append(u.seen, p.id)
  FROM up AS u JOIN project AS p ON p.id = u.at_parent
  WHERE coalesce(u.at_parent, '') <> '' AND NOT list_contains(u.seen, p.id)
),
by_parent AS (
  SELECT project_id, at_id AS root_id FROM up WHERE coalesce(at_parent, '') = ''
),
by_hierarchy AS (
  SELECT p.id AS project_id, arg_min(r.id, h.n) AS root_id
  FROM project AS p,
       unnest(string_split(p.project_hierarchy, '.')) WITH ORDINALITY AS h(x, n),
       project AS r
  WHERE r.id = h.x AND coalesce(r.parent, '') = ''
  GROUP BY p.id
),
by_type_id AS (
  SELECT type_id, min(line) AS line FROM project_type GROUP BY type_id
)
SELECT p.*, coalesce(bp.root_id, bh.root_id) AS root_id, ti.line AS protocol_line
FROM project AS p
LEFT JOIN by_parent AS bp ON bp.project_id = p.id
LEFT JOIN by_hierarchy AS bh ON bh.project_id = p.id
LEFT JOIN by_type_id AS ti ON ti.type_id = p.project_type_id
ORDER BY p.line
