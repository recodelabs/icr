-- Targets of projects that are not a root project and whose boundary was
-- not exported: no Group is written for them. transform.py counts these in
-- its report as "project target: boundary not exported (child project)",
-- deleted targets included, as here.
SELECT p.id AS project_id, t.id AS target_id, p.boundary
FROM project AS p
JOIN target AS t ON t.project_id = p.id
WHERE p.root_id IS NOT NULL AND p.id <> p.root_id
  AND NOT EXISTS (SELECT 1 FROM boundary AS b WHERE b.code = p.boundary)
ORDER BY p.line, t.target_index
