-- The DIGIT product catalogue, one row per product variant whose product
-- was exported, in the order of product_variant.ndjson. It is
-- transform.py's products.py: the maps that write a product (an
-- ActivityDefinition's product, later a delivery or a stock movement) read
-- these columns. A variant not in this table is written with a local code
-- only, labelled "DIGIT product variant <id>".
--
-- The tables below are the demo tenant's (products.py): DIGIT's product
-- type decides the kind, and the product name (trimmed, lower case) the
-- standard code. A variant's label is its SKU, or the product name when the
-- SKU is empty.
--
-- If a file has an id twice, transform.py keeps the last line; so does this.
WITH type_kind(product_type, kind) AS (
  VALUES ('TONIC', 'vaccine'), ('DRUG', 'drug'), ('TABLET', 'drug'),
         ('BEDNET', 'commodity'), ('RESIDUAL_SPRAY', 'commodity')
),
standard(kind, key, system, code, display) AS (
  VALUES ('drug', 'sp', 'http://www.whocc.no/atc', 'P01BD51', 'sulfadoxine and pyrimethamine'),
         ('drug', 'automated-sp', 'http://www.whocc.no/atc', 'P01BD51', 'sulfadoxine and pyrimethamine'),
         ('drug', 'updated-automated-sp', 'http://www.whocc.no/atc', 'P01BD51', 'sulfadoxine and pyrimethamine'),
         ('drug', 'aq', 'http://www.whocc.no/atc', 'P01BA06', 'amodiaquine'),
         ('drug', 'ivermectin', 'http://www.whocc.no/atc', 'P02CF01', 'ivermectin'),
         ('drug', 'albendazole', 'http://www.whocc.no/atc', 'P02CA03', 'albendazole'),
         ('drug', 'azm', 'http://www.whocc.no/atc', 'J01FA10', 'azithromycin'),
         ('drug', 'vas', 'http://www.whocc.no/atc', 'A11CA01', 'retinol (vitamin A)'),
         ('drug', 'vitamin a', 'http://www.whocc.no/atc', 'A11CA01', 'retinol (vitamin A)'),
         ('drug', 'vit a', 'http://www.whocc.no/atc', 'A11CA01', 'retinol (vitamin A)'),
         ('vaccine', 'mr vaccine', 'http://hl7.org/fhir/sid/cvx', '04', 'measles and rubella virus vaccine'),
         ('vaccine', 'mr', 'http://hl7.org/fhir/sid/cvx', '04', 'measles and rubella virus vaccine'),
         -- A commodity is coded by its product type, not its name.
         ('commodity', 'BEDNET', 'https://icr.healthcampaigns.org/CodeSystem/icr-commodity-class-cs', 'llin', 'Long-lasting insecticidal net (LLIN)'),
         ('commodity', 'RESIDUAL_SPRAY', 'https://icr.healthcampaigns.org/CodeSystem/icr-commodity-class-cs', 'irs-insecticide', 'IRS insecticide')
),
last_variant AS (
  SELECT * FROM variant QUALIFY row_number() OVER (PARTITION BY id ORDER BY line DESC) = 1
),
last_product AS (
  SELECT * FROM product QUALIFY row_number() OVER (PARTITION BY id ORDER BY line DESC) = 1
),
catalogue AS (
  SELECT v.line, v.id, p.type AS product_type, k.kind,
         regexp_replace(coalesce(nullif(v.sku, ''), p.name), '^\s+|\s+$', '', 'g') AS label,
         lower(regexp_replace(p.name, '^\s+|\s+$', '', 'g')) AS product_name
  FROM last_variant AS v
  JOIN last_product AS p ON p.id = v.product_id
  LEFT JOIN type_kind AS k ON k.product_type = p.type
)
SELECT c.id AS product_variant_id, c.label, c.kind, c.product_type,
       s.system AS standard_system, s.code AS standard_code, s.display AS standard_display,
       CASE WHEN c.kind = 'commodity' AND c.product_type = 'BEDNET' THEN 'nets'
            WHEN c.kind = 'drug' THEN 'tablets'
            WHEN c.kind = 'vaccine' THEN 'doses'
            ELSE 'units' END AS unit,
       CASE WHEN c.kind = 'commodity' AND c.product_type = 'BEDNET' THEN '{Net}'
            WHEN c.kind = 'drug' THEN '{tbl}'
            WHEN c.kind = 'vaccine' THEN '{dose}'
            ELSE '1' END AS unit_code
FROM catalogue AS c
LEFT JOIN standard AS s
  ON s.kind = c.kind AND s.key = CASE WHEN c.kind = 'commodity' THEN c.product_type ELSE c.product_name END
ORDER BY c.line
