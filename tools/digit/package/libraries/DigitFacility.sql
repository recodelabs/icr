-- DIGIT facilities, each once, as DIGITFacilityRow records (the columns are
-- named as its elements) for the DIGITFacilityToICR map.
--
-- The facility search can return the same facility on two pages: those
-- copies are the same row, and DISTINCT keeps one. Copies that differ are
-- two rows with one id, which the package's data test refuses.
--
-- boundaryCode is the facility's locality only when that boundary was
-- exported (project/digit.md: a facility's partOf is its locality boundary).
-- A coordinate DIGIT left out is 0, as transform.py reads it.
SELECT DISTINCT
       f.id AS "id",
       f.client_reference_id AS "clientReferenceId",
       f.name AS "name",
       f.usage AS "usage",
       f.is_permanent AS "isPermanent",
       f.is_deleted AS "isDeleted",
       CASE WHEN f.latitude IS NOT NULL OR f.longitude IS NOT NULL THEN coalesce(f.latitude, 0) END AS "latitude",
       CASE WHEN f.latitude IS NOT NULL OR f.longitude IS NOT NULL THEN coalesce(f.longitude, 0) END AS "longitude",
       b.code AS "boundaryCode"
FROM facility AS f
LEFT JOIN boundary AS b ON b.code = f.locality
ORDER BY "id"
