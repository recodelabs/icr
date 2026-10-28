-- One row per campaign × activity × target Group: the ICHD targets as the campaigns hold them
-- (CarePlan.activity.detail → planning-denominator, the IcrCampaignActivity view), with the
-- campaign's place and the Group's code, display, count and age band.
-- admin_level is cast to INTEGER, the type the pages had from the locations table
-- (LocationHierarchy gives a BIGINT, which JavaScript reads as a BigInt).
SELECT a.campaign_id, c.status AS campaign_status, c.location_id, c.location_name,
       CAST(c.admin_level AS INTEGER) AS admin_level,
       COALESCE(c.admin1_name, c.location_name) AS region,
       a.activity_key, a.activity_status,
       a.denominator_id AS group_id,
       p.code AS target_code,
       p.code_text AS target_name,
       p.quantity, p.age_low, p.age_high, p.age_unit
FROM activity AS a
JOIN calendar AS c ON c.campaign_id = a.campaign_id
LEFT JOIN target_population AS p ON p.group_id = a.denominator_id
ORDER BY c.admin_level, region, c.location_name, a.activity_key, group_id
