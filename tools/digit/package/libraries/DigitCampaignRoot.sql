-- Every root project, with what its CarePlan takes from it and from its
-- project type and campaign record, and the reason when it gets no
-- CarePlan: when its project type is not exported, when it has no start,
-- or when it has no at-risk target to be the subject (transform.py's
-- write_campaigns, in that order). DigitCampaign writes the rows without a
-- reason.
--
-- The campaign record is the one of the project's campaign number
-- (referenceID) created for this project, else with status created, else
-- the last changed; among equals the first in the file.
--
-- The status is draft when that record is drafted or creating; otherwise
-- completed when the end is before the as-of time, 2026-10-28T00:00:00Z
-- (1793145600000 ms, the date of the export; transform.py's AS_OF_MS), and
-- active otherwise.
--
-- Times are epoch milliseconds; one below 10^11 is taken as seconds, and 0
-- or less as no time (fhirutil.norm_ms).
WITH root AS (
  SELECT p.*, t.protocol_id, t.code, t.campaign_type, t.campaign_type_display,
         t.beneficiary_type AS type_beneficiary_type
  FROM project AS p
  LEFT JOIN project_type AS t ON t.line = p.protocol_line
  WHERE p.id = p.root_id
),
record AS (
  SELECT r.id AS root_id, c.id, c.campaign_number, c.campaign_name, c.status, c.start_date, c.end_date
  FROM root AS r
  JOIN campaign AS c ON c.campaign_number = r.reference_id
  QUALIFY row_number() OVER (PARTITION BY r.id ORDER BY coalesce(c.project_id = r.id, false) DESC,
                                                       coalesce(c.status = 'created', false) DESC,
                                                       coalesce(c.last_modified_time, 0) DESC, c.line) = 1
),
ms AS (
  SELECT r.*, c.id AS record_id, c.campaign_number, c.campaign_name, c.status AS record_status,
         CAST(trunc(CASE WHEN r.start_date > 0 THEN CASE WHEN r.start_date < 1e11 THEN r.start_date * 1000 ELSE r.start_date END
                         WHEN c.start_date > 0 THEN CASE WHEN c.start_date < 1e11 THEN c.start_date * 1000 ELSE c.start_date END END) AS BIGINT) AS start_ms,
         CAST(trunc(CASE WHEN r.end_date > 0 THEN CASE WHEN r.end_date < 1e11 THEN r.end_date * 1000 ELSE r.end_date END
                         WHEN c.end_date > 0 THEN CASE WHEN c.end_date < 1e11 THEN c.end_date * 1000 ELSE c.end_date END END) AS BIGINT) AS end_ms
  FROM root AS r
  LEFT JOIN record AS c ON c.root_id = r.id
),
-- The subject: the root project's first at-risk Group of the campaign's
-- beneficiary type, else its first at-risk Group.
subject AS (
  SELECT m.id AS root_id,
         coalesce(
           (SELECT arg_min(g.group_id, [g.line, g.target_index])
            FROM target_group AS g
            WHERE g.project_id = m.id AND g.is_root AND g.denominator_type = 'at-risk'
              AND g.beneficiary_type = coalesce(nullif(m.beneficiary_type, ''), nullif(m.type_beneficiary_type, ''), 'INDIVIDUAL')),
           (SELECT arg_min(g.group_id, [g.line, g.target_index])
            FROM target_group AS g
            WHERE g.project_id = m.id AND g.is_root AND g.denominator_type = 'at-risk')) AS group_id
  FROM ms AS m
),
campaign_row AS (
  SELECT m.*, s.group_id AS subject,
         CASE WHEN m.record_status IN ('drafted', 'creating') THEN 'draft'
              WHEN m.end_ms < 1793145600000 THEN 'completed'
              ELSE 'active' END AS status,
         coalesce(nullif(m.campaign_name, ''), nullif(m.name, ''), m.id) AS title,
         CASE WHEN b.code IS NOT NULL THEN 'dgt-' || regexp_replace(m.boundary, '[^A-Za-z0-9.-]', '-', 'g') END AS geography
  FROM ms AS m
  LEFT JOIN subject AS s ON s.root_id = m.id
  LEFT JOIN boundary AS b ON b.code = m.boundary
)
SELECT *,
       CASE WHEN protocol_id IS NULL THEN 'project type not exported'
            WHEN start_ms IS NULL THEN 'no start date'
            WHEN subject IS NULL THEN 'no target to use as CarePlan.subject'
       END AS reason
FROM campaign_row
ORDER BY id
