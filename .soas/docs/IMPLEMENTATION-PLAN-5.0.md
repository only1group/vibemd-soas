# SOAS 5.0 Implementation Plan

## Dependency order

1. Establish and retain the 4.0 baseline.
2. Add dependency-free repository validation and regression tests.
3. Make capability, finding, execution, outcome, selection and output contracts
   machine-enforceable.
4. Define shared evidence, severity, closure, active-testing, outcome and output
   protocols.
5. Add deterministic signal selection and dependency closure.
6. Reconcile standards references.
7. Migrate the complete capability library to the 2.0 capability contract.
8. Add selection and assurance golden fixtures.
9. Align templates, examples, instructions, contribution guidance and release
   records.

## Review gates

- All YAML and JSON parses.
- All 72 catalogue and capability identities agree.
- All journey, dependency and standards references resolve.
- Duplicate IDs and dependency cycles fail validation.
- Different architecture fixtures resolve predictable minimal capability sets.
- Finding examples cover open, accepted risk, ready for verification and closed.
- Closed findings without regression evidence fail.
- Incomplete evidence never maps to a positive outcome.
- Root distribution documents match the `.soas` package documents.

## Compatibility

The capability, finding, execution and structured register contracts are
intentionally incompatible with 4.0 documents. This requires SOAS 5.0.0.
Historical generated assurance outputs are not rewritten; migration applies to
new executions and maintained capability definitions.
