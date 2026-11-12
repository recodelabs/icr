-- Facilities whose locality is a boundary code that was not exported: their
-- Location is written without partOf. transform.py counts these in its
-- report as "facility: locality boundary not exported (partOf left empty)".
SELECT DISTINCT f.id AS "id", f.locality AS "locality"
FROM facility AS f
WHERE f.locality <> ''
  AND NOT EXISTS (SELECT 1 FROM boundary AS b WHERE b.code = f.locality)
ORDER BY "id"
