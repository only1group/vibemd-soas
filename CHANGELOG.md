# Changelog

All notable changes to VibeMD SOAS will be documented in this file.

The format is inspired by *Keep a Changelog* and the project follows Semantic Versioning.

---

## [5.0.1] - 2026-07-24

### Fixed

- Pinned ISO 22301:2019 with Amendment 1:2024 and retained the in-development
  revision as advisory.
- Replaced the ambiguous ISO 9241 family identifier with part-specific
  references for usability, interaction, information presentation,
  accessibility and human-centred design.
- Extended standards validation across all machine-readable YAML sources with
  fail-closed unknown and duplicate ID tests.
- Added deterministic offline resolution tests for ISO 22301, ISO 31000 and the
  selected ISO 9241 parts.

## [5.0.0] - 2026-07-23

### Added

- Dependency-free repository validation and regression tests.
- Executable strict capability, finding, execution, outcome, selection and
  output-inventory contracts.
- Evidence-fitness, calibrated severity, capability-outcome, active-testing,
  output and independent-closure protocols.
- Deterministic signal-based selection with dependency closure and golden
  architecture fixtures.
- Domain-specific objectives, evidence, inspection procedures, positive and
  negative tests, failure modes and sufficiency rules across all 72 capabilities.
- Four finding lifecycle examples and nine assurance scenario fixtures.
- ADRs, migration guidance, baseline validation report and full concern
  traceability.

### Changed

- Capability definitions use contract version 2.0.0.
- Finding and execution contracts now reject unknown fields and enforce
  lifecycle-specific evidence.
- Standards entries record official sources and resolution limitations; added
  ISO 31000, ISO 22301 and ISO 9241.
- Structured register headers now carry evidence fitness, scope, confidence,
  priority and expiry data.

### Compatibility

- This is a major release. New executions and findings must use the 5.0
  contracts. Historical generated outputs should remain unchanged.

## [4.0.0] - 2026-07-18

### Added

- Initial public release of VibeMD SOAS.
- Instruction-native architecture with no standalone runtime.
- Guided Engineer and Lead Peer profiles.
- Greenfield Build, Lead Peer Assurance, Continuous Engineering and Remediation journeys.
- 72 reusable engineering and assurance capabilities.
- Global standards registry.
- Jurisdiction overlays for Australia, the United States and Europe.
- Controlled learning model.
- Permission-based remediation workflow.
- Professional report, register and ADR templates.
- Execution and finding schemas.
- MIT License.
- NOTICE and DISCLAIMER.
- CONTRIBUTING guide.
- This CHANGELOG.

### Design Principles

- Global engineering first.
- Jurisdiction overlays optional.
- Industry overlays excluded from the core.
- Evidence before opinion.
- Repository-first discovery.
- Human approval before implementation.
