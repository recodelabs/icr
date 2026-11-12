-- Root projects that are not written as a CarePlan, with the reason, as
-- transform.py's report gives them under "skipped": "root project: project
-- type not exported", "root project: no start date (CarePlan.period 1..1)"
-- and "root project: no target to use as CarePlan.subject (1..1)".
SELECT id AS project_id, reason
FROM campaign_root
WHERE reason IS NOT NULL
ORDER BY id
