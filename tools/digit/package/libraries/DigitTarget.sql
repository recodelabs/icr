-- The target populations as DIGITTargetRow records (the columns are named
-- as its elements), in the order transform.py writes them.
SELECT group_id AS "id", target_id AS "targetId", project_id AS "projectId",
       coalesce(project_name, 'None') AS "projectName", unit AS "unit",
       count_label AS "countLabel", place AS "place", denominator_type AS "denominatorType",
       quantity AS "quantity", geography AS "geography"
FROM target_group
ORDER BY line, target_index, field_index
