-- The DIGIT project types (MDMS), one row per line of
-- mdms_project_type.ndjson, with what the PlanDefinition, the
-- ActivityDefinitions and the CarePlans take from it.
--
-- protocol_id is the PlanDefinition's id: dgt- and the code. Two codes
-- that give the same id when compared without case (LLIN-mz twice and
-- LLIN-Mz in the demo) are told apart as transform.py does: the second and
-- later get a dash and the first 8 letters and digits of the MDMS data.id.
--
-- campaign_type is the ICR campaign type of the code: transform.py's table
-- (CAMPAIGN_TYPE) for the demo tenant, and for another code
-- itn-distribution when it names nets (llin, bednet, itn, sk), mda
-- otherwise.
WITH named AS (
  SELECT *, 'dgt-' || regexp_replace(code, '[^A-Za-z0-9.-]', '-', 'g') AS plain_id
  FROM project_type
),
numbered AS (
  SELECT *, row_number() OVER (PARTITION BY lower(plain_id) ORDER BY line) AS same_id
  FROM named
),
typed AS (
  SELECT *,
         CASE code WHEN 'CO-DELIVERY' THEN 'integrated' WHEN 'MR-DN' THEN 'smc'
                   WHEN 'POLIO' THEN 'vaccination-sia' WHEN 'Oncho' THEN 'mda' WHEN 'NTD' THEN 'mda'
                   WHEN 'IRS-mz' THEN 'irs' WHEN 'DEFAULT' THEN 'mda'
                   ELSE CASE WHEN regexp_matches(lower(code), 'llin|bednet|itn|sk') THEN 'itn-distribution' ELSE 'mda' END
         END AS campaign_type
  FROM numbered
)
SELECT t.line, t.type_id, t.code, t.name, t.is_active,
       CASE WHEN t.same_id = 1 THEN t.plain_id
            ELSE t.plain_id || '-' || left(regexp_replace(coalesce(t.type_id, 'None'), '[^A-Za-z0-9]', '', 'g'), 8)
       END AS protocol_id,
       t.beneficiary_type, t.observation_strategy, t.eligibility_criteria, t.task_procedure,
       t.valid_min_age, t.valid_max_age,
       t.campaign_type, d.display AS campaign_type_display
FROM typed AS t
JOIN (VALUES ('smc', 'Seasonal malaria chemoprevention'),
             ('integrated', 'Integrated / multi-intervention campaign'),
             ('mda', 'Mass drug administration (NTD preventive chemotherapy)'),
             ('vaccination-sia', 'Vaccination campaign (SIA)'),
             ('irs', 'Indoor residual spraying'),
             ('itn-distribution', 'ITN mass distribution'),
             ('vitamin-a', 'Vitamin A supplementation')) AS d(code, display)
  ON d.code = t.campaign_type
ORDER BY t.line
