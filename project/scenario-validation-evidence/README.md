# Negative-test probes & validator evidence

Deliberately non-conformant FHIR JSON instances and validator logs backing the
negative claims in `../james-scenarios-validation-report.md`. They are **not** part
of the IG (they would break the build/gallery by design); they live here as
re-runnable evidence.

| File | Backs | Expected result |
|---|---|---|
| `probe-task-no-strategy.json` | S12 | FAILS — delivery-strategy 1..1 forces a strategy on logistics Tasks |
| `probe-report-realtime-unstratified.json` | S9 | FAILS — Measure-declared stratifiers are mandatory on every report |
| `probe-tally-doc-stratifier.json` | S11 | FAILS — a locally-added DOC stratifier has no match in the Measure |
| `probe-medadmin-text-only-dosage.json` | cross-cutting #1 | FAILS — base `mad-1` (shipped-example defect shape) |
| `probe-group-in-group-base.json` | S8/S7 | PASSES — plain R4 allows Group-in-Group (refutes reply c66) |
| `probe-group-in-group.json` | S8 + methods note | Passes despite violating ICRDeliveryUnit — validator does not type-check unresolved references |
| `probe-task-focus-careplan.json` | S4 + methods note | Passes despite violating ICRCampaignTask.focus — same validator blind spot |
| `probe-location-supervisory-no-overlay.json` | Finding 2 (S3) | PASSES — supervisory area overlaying nothing; the documented `icr-loc-overlays` invariant is not in the FSH |
| `probe-location-admin-no-identifier.json` | Finding 2 (S3) | PASSES — admin unit with no identifier; the documented `icr-loc-admin-id` invariant is not in the FSH |

Logs (ANSI-stripped validator output):

- `validator-probes.log` — the run over these probes
- `validator-probes-location.log` — the run over the two Location-invariant probes (added Aug 10)
- `validator-committed-instances.log` — final run over the 88 committed `sc-*` instances (88/88 pass)
- `validator-shipped-examples.log` — spot-check of 11 shipped `example-*` instances (5 fail)

## Re-running

```bash
cd ig && sushi .   # compile the IG so profiles exist in fsh-generated/resources
java -jar validator_cli.jar project/scenario-validation-evidence \
  -version 4.0.1 -ig ig/fsh-generated/resources -tx n/a
```

(`validator_cli.jar`: https://github.com/hapifhir/org.hl7.fhir.core/releases — needs Java 17+.)

When the IG fixes the underlying issues, the FAILS probes should flip to passing
(or the blind-spot probes start failing on a server that resolves references) —
usable as regression markers.
