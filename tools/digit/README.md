# DIGIT → ICR importer

Moves a DIGIT HCM tenant's campaign data into an ICR FHIR server, following the mapping in
[[digit]] (`project/digit.md`) and the profiles added in `ig/` for it ([[ig-gaps-from-digit]]).
First used on the DIGIT demo tenant (`health-demo.digit.org`, tenant `demo`, fake load-test
data), loaded into `fhir-digit.healthcampaigns.org` (hfs; see `tools/hapi/gcp/hfs.sh`).

Three steps, each a plain script (Python standard library; `fhir-pipes` for the load):

| Step | Script | Reads | Writes |
| --- | --- | --- | --- |
| Extract | `extract.py`, `extract_ref.py` | DIGIT's `_search` APIs, 1,000 rows a page | `$DIGIT_WORK/raw/<entity>.ndjson` |
| Transform | `transform/transform.py` | the raw export | `$DIGIT_WORK/out/<ResourceType>.ndjson`, `report.json` |
| Check | `transform/check.py` | the output | exit 0 when every reference resolves and the cheap profile rules hold |
| Load | `load.sh` | the output | the FHIR server, through its gateway, as transaction bundles |

```bash
export DIGIT_WORK=/Volumes/maximus/digit-work/digit      # keep it off the boot disk: the demo is ~3 GB raw, ~1 GB out
export DIGIT_FIELD_USER=… DIGIT_FIELD_PASSWORD=…        # a DISTRIBUTOR login: tasks, households, stock, referrals
export DIGIT_ADMIN_USER=… DIGIT_ADMIN_PASSWORD=…        # an admin login: campaigns, projects, boundaries, products, MDMS
python3 -I extract.py && python3 -I extract_ref.py && python3 -I extract_ref.py projects   # ~20 min for the demo
python3 -I transform/transform.py && python3 -I transform/check.py                        # ~2 min + ~1 min
TYPES="Location Organization Practitioner Patient Group PlanDefinition ActivityDefinition CarePlan ServiceRequest Task MedicationAdministration Immunization SupplyDelivery" \
  ./load.sh                                                                                 # API key from ~/.config/icr/digit-loader.env
```

Load the IG's conformance resources (profiles, extensions, terminology, SearchParameters) into
the server first. Ids are deterministic (`dgt-<clientReferenceId>`), so every step can be re-run:
the same resources are updated, never duplicated.

## Rules the transform applies

- **Only what is linked to a campaign** — records that trace to a root project emitted as an
  ICRCampaign. Boundaries, facilities and protocols are imported regardless.
- **Clients and workers by linkage, not by `isSystemUser`.** DIGIT defines `isSystemUser` only as
  "registered with the egov-user service" (a login). Clients are individuals linked as household
  members or project beneficiaries; workers are EMPLOYEE logins that created imported records.
- **One visit Task per household visit**: per-person DIGIT tasks are grouped by round,
  household, worker and a 2-hour window; each delivered product is a delivery event. The task's
  status decides the outcome (the demo's `isDelivered` flags are unreliable).
- **Boundaries** become admin-unit Locations named from the code; DIGIT holds no geometry or
  localised names for them.

`report.json` lists counts by profile, skipped records by reason, and the visit statistics.

## Known limits

- Times are written in UTC; the DIGIT demo records India Standard Time.
- No `fhir-pipes digit` subcommand yet; this is the prototype for one (like `fhir-pipes dhis2`).
