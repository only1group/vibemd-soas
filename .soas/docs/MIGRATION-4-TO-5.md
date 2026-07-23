# Migrating SOAS 4.x to 5.0

SOAS 5.0 remains instruction-native and requires no runtime in a consuming
application. The included Ruby validator is contributor and framework
self-assurance tooling.

## Capability definitions

- Change capability version to `2.0.0`.
- Replace generic `activities` with `control_objectives`,
  `inspection_procedures`, `test_recipes` and `failure_modes`.
- Add `scope_signals`, evidence sufficiency, output content, dependencies and
  domain severity considerations.
- Include empty `advisory` and `dependencies` arrays when none apply.
- Unknown top-level fields are rejected; propose contract extensions explicitly.

## Findings

New findings must add structured confidence, priority, affected scope, risk,
observed/potential impact, authoritative basis, owner state and evidence
metadata. Accepted risk requires approval and expiry. Closed findings require a
passed verification, verifier and independence classification, regression
evidence, residual risk and reopening conditions.

Do not rewrite historical findings merely to make them validate. Mark them as
legacy records or migrate a copy with a documented provenance link.

## Executions and outcomes

New manifests lock the repository commit and dirty state, target, tools,
capability versions and selection reasons, dependency and standards resolution,
evidence register, identities and output inventory. A finalized execution also
requires completion time, overall outcome and generated outputs.

Map old ambiguous completion values conservatively:

- complete with sufficient objective evidence → `satisfied` or `finding-raised`;
- evidence missing or unfit → `insufficient-evidence`;
- selected but not run → `not-executed`;
- affirmatively outside scope → `not-applicable`;
- prevented after starting → `blocked`.

## Registers

Start new 5.0 registers from the supplied headers. Preserve 4.x registers as
historical outputs. Cross-link migrated records rather than modifying history.

## Selection

Journeys retain baseline capabilities but must evaluate
`orchestrator/selection-rules.yaml`, record exclusions and add transitive
dependencies. A material unknown is recorded as uncertainty, not used as an
exclusion.
