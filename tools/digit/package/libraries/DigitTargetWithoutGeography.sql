-- Target Groups of root projects whose boundary was not exported: the Group
-- is written without a geography characteristic. transform.py counts these
-- in its report as "root project target: boundary not exported (Group
-- without geography)".
SELECT group_id, project_id
FROM target_group
WHERE geography IS NULL
ORDER BY line, target_index, field_index
