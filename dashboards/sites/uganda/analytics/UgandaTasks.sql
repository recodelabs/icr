-- The campaign tasks: one per district and activity for now, with the name and region of the
-- Location where the work happens. Read by the plan page (src/plan.md).
SELECT t.task_id, t.campaign_id, t.activity_key,
       t.location_id, t.location_name, t.location_admin1_name AS region,
       t.status, t.intent, t.strategy, t.origin, t.execution_start, t.execution_end
FROM task AS t
ORDER BY region, location_name, activity_key, task_id
