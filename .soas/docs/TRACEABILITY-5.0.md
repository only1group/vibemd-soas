# SOAS Validation and Improvement Traceability

| Concern | Disposition | Evidence | Primary changes | Regression coverage |
|---|---|---|---|---|
| A — generic capabilities | Accepted; “identical activities” revised to four common plus one name-variable activity. | `VALIDATION-BASELINE.md` and full-library traversal. | `standards/capability.schema.yaml`; all files under `capabilities/`; shared orchestrator protocols. | Complete-library schema validation, uniqueness and dependency-cycle checks; assurance fixtures compare domain evidence. |
| B — lead-peer coverage | Accepted. | Fixed 4.0 journey contained no resolver. | `journeys/lead-peer-assurance.yaml`; `orchestrator/scope-resolution-protocol.yaml`; `orchestrator/selection-rules.yaml`. | Nine exact selection fixtures covering API, tenant, mobile, AI, migration, cloud delivery, scale, UI and clean control. |
| C — descriptive contract | Accepted. | Former schema only contained `required` and prose `fields`. | Executable strict capability JSON Schema in YAML; 2.0 capability migration. | Every capability is validated; unknown fields and missing required fields fail. |
| D — finding mismatch | Accepted. | Former schema omitted confidence, affected scope, basis and owner and allowed empty evidence objects. | `schemas/finding.schema.json`; four lifecycle examples; register template. | Schema examples plus negative closed-without-regression test. |
| E — weak execution lock | Accepted. | Former schema did not identify repository revision, dirty state, target, tools, outcomes or outputs. | `schemas/execution.schema.json`; execution template. | Template schema validation and finalized-state conditional requirements. |
| F — incomplete standards | Accepted; exhaustive unresolved list was exactly the three suspected ISO IDs. | Programmatic mapping comparison. | `standards/registry.yaml`; standards resolution protocol. | Every normative, advisory and conditional mapping must resolve; registry metadata is required. |
| G — absolute evidence hierarchy | Accepted. | Six-level hierarchy in former `SOAS.md`. | `SOAS.md`; `orchestrator/evidence-protocol.yaml`; evidence register. | Protocol and header contract validation. |
| H — severity calibration | Accepted. | Repeated five-line generic severity block in every capability. | `orchestrator/severity-protocol.yaml`; capability severity considerations; finding priority/confidence fields. | Capability schema and fixture severity expectations. |
| I — overstated completion | Accepted. | No capability outcome vocabulary or objective result contract. | `orchestrator/capability-outcome-protocol.yaml`; `schemas/capability-outcome.schema.json`; report template. | Outcome vocabulary test and three insufficient-evidence fixtures that prohibit invented findings. |
| J — closure independence | Accepted. | Former closure protocol contained one independence sentence. | `orchestrator/closure-protocol.yaml`; finding schema; remediation template. | Closed example and negative missing-closure-evidence test. |
| K — active testing | Accepted. | No protocol existed. | `orchestrator/active-testing-protocol.yaml`; master instruction. | Required protocol parses and is part of package validation. |
| L — output/self-testing | Accepted. | Markdown/CSV templates had no cross-contract checks and no test suite existed. | `orchestrator/output-protocol.yaml`; output inventory schema; register templates; `tools/validate_soas.rb`; `test/`. | Required headers, references, schemas, examples, selection fixtures and assurance fixtures validate through `make validate && make test`. |

## Definition-of-done mapping

- YAML and JSON parsing: `tools/validate_soas.rb`.
- Schema validation: capability library, finding examples and execution template.
- Catalogue/reference integrity: catalogue path/ID, journey, dependency and
  standards checks.
- Duplicate IDs and cycles: automatic validation failure.
- Deterministic selection: exact expected capability sets in fixture YAML.
- Finalized executions and closed findings: lifecycle conditions in schemas.
- Insufficient evidence: explicit non-positive protocol and tests.
- Closure independence and active-testing authorization: shared protocols.
- Documentation and compatibility: ADRs, migration guide, changelog and 5.0
  version.

No consuming application source or historical generated assurance output was
modified.
