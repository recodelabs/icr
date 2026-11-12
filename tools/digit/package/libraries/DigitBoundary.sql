-- Every DIGIT boundary of every hierarchy as DIGITBoundaryRow records (the
-- columns are named as its elements) for the DIGITBoundaryToICR map: with
-- its hierarchy, its level (0 for a top boundary) and its parent's code.
--
-- The rows are in the order transform.py writes the boundaries: tree by
-- tree in the order of boundary_tree.ndjson, and in each tree each boundary
-- before its children, the children in the order DIGIT lists them (a
-- depth-first walk). The walk keeps a sort key per boundary: the tree's line
-- and then the position of each boundary on the way down among its
-- siblings, so [2, 1, 3] is the third child of the first top boundary of the
-- tree on line 2. Sorting by it gives that order.
--
-- The views give each list of codes (the top boundaries of a tree, the
-- children of a boundary) as JSON text, which from_json reads as a list.
-- A boundary code is unique in the tenant (the data test "one boundary per
-- Location id" checks it), so the joins on code find one boundary each.
WITH RECURSIVE edge AS (
  SELECT b.code AS parent, u.child, u.n
  FROM boundary AS b, unnest(from_json(b.children, '["VARCHAR"]')) WITH ORDINALITY AS u(child, n)
),
walk AS (
  SELECT t.hierarchy_type, u.code, NULL::VARCHAR AS parent, 0 AS level, [t.line, u.n] AS sort_key
  FROM tree AS t, unnest(from_json(t.top, '["VARCHAR"]')) WITH ORDINALITY AS u(code, n)
  UNION ALL
  SELECT w.hierarchy_type, e.child, w.code, w.level + 1, list_append(w.sort_key, e.n)
  FROM walk AS w JOIN edge AS e ON e.parent = w.code
)
SELECT w.code AS "code", b.id AS "id", b.boundary_type AS "boundaryType",
       w.hierarchy_type AS "hierarchyType", w.level AS "level", w.parent AS "parent"
FROM walk AS w JOIN boundary AS b ON b.code = w.code
ORDER BY w.sort_key
