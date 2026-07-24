# SOAS 4.0 Validation Baseline

## Baseline identity

- Repository commit: `80021b685dcfa3ef3d0a72c7ea742c66d87cdc1f`
- Worktree state: dirty; `feedback/` was an existing untracked directory and
  was treated as user-owned input.
- Existing automated validation: none discovered.
- Existing machine-readable contracts: finding and execution JSON Schemas;
  the capability “schema” was descriptive YAML.

## Reproduction

The pre-change baseline was reproduced with Git, `find`, `rg`, Ruby's standard
YAML/JSON parsers and a programmatic traversal of the complete capability
library. Representative files from every category were also inspected.

Key commands:

```sh
git rev-parse HEAD
git status --porcelain=v1
find .soas/capabilities -type f -name '*.yaml' | wc -l
ruby -ryaml -rjson -e 'Dir[".soas/capabilities/**/*.yaml"].each { |f| YAML.load_file(f) }'
```

The implemented repeatable replacement is:

```sh
make validate
make test
```

## Observations and disposition

| Concern | Baseline evidence | Disposition | Response | Compatibility |
|---|---|---|---|---|
| A — generic capabilities | 72 files, 72 catalogue entries and 72 unique IDs; every file had five activities; four activities, all questions, evidence blocks, exit criteria and severity blocks were shared; no dependency field existed. | Accepted, with wording revised because one activity varied by capability name. | Migrate all capabilities to objectives, signals, domain evidence, inspection procedures, positive/negative recipes, failure modes, sufficiency and dependencies. | Breaking capability contract. |
| B — lead-peer coverage | Journey contained a fixed assurance list and no deterministic signal resolver. | Accepted. | Add shared trigger matrix, recorded exclusions and dependency closure with architecture fixtures. | Additive journey behavior; assessment scope can expand. |
| C — descriptive capability contract | `standards/capability.schema.yaml` only listed fields and descriptions. | Accepted. | Replace it with strict JSON Schema expressed as YAML and validate all 72 files. | Breaking for old capability extensions. |
| D — finding inconsistency | Master instructions required confidence, affected scope, basis and owner; schema omitted or left these unconstrained and allowed closure without closure evidence. | Accepted. | Strict lifecycle-aware finding schema and examples. | Breaking finding document contract. |
| E — execution context | Schema did not require commit, dirty state, target, tools, outcomes, evidence identity or output inventory. | Accepted. | Lifecycle-aware execution contract with finalized-state requirements. | Breaking execution manifest contract. |
| F — standards resolution | `ISO-31000`, `ISO-22301` and a generic `ISO-9241` reference were absent from the 4.0 registry; no other unregistered normative IDs were found. | Accepted. The generic family reference required part-specific correction in 5.0.1. | Add entries and reproducibility metadata; lint every mapping; use part-specific identifiers for independently versioned standards. | Additive registry contract; metadata fields now required. |
| G — evidence hierarchy | Master instructions used an absolute six-level source ordering. | Accepted. | Replace with claim-specific evidence fitness and conflict handling. | Judgment protocol change. |
| H — severity | Only repeated generic prose existed in capabilities. | Accepted. | Add calibrated dimensions, boundary examples and separation from priority/confidence/acceptance. | Vocabulary retained; semantics strengthened. |
| I — completion semantics | No per-capability outcome vocabulary or objective-level sufficiency contract existed. | Accepted. | Add six distinct outcomes and prohibit positive conclusions from incomplete states. | Breaking outcome semantics. |
| J — closure independence | One sentence prohibited implementer assertion but did not define roles, independence or AI context. | Accepted. | Add severity-proportionate independence, self-verification disclosure and reopening rules. | Strengthened closure requirements. |
| K — active testing | No authorization and safety protocol existed. | Accepted. | Add non-destructive default, explicit-approval list, limits, stops and cleanup. | Safer behavioral restriction. |
| L — outputs/self-testing | CSV headers and Markdown templates had no consistency validation; no self-test suite existed. | Accepted. | Add output inventory contract, register checks, examples and golden fixtures. | Structured output columns changed. |

## Baseline risks

The 4.0 contracts could make assessments of different commits appear
equivalent, allow insufficient evidence to be interpreted positively and allow
closed findings without independent closure evidence. Generic capability
instructions also made domain-specific evidence requests unreliable.

## Planned response

The response follows this dependency order: validators, contracts, assurance
protocols, selection, capability migration, fixtures, then documentation and
release. Architectural decisions are recorded under `docs/adrs/`.
