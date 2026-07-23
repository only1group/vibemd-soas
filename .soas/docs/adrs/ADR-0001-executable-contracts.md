# ADR-0001: Executable, strict SOAS contracts

- Status: Accepted
- Date: 2026-07-23

## Context

The 4.0 capability contract was descriptive and output schemas allowed unknown
or materially incomplete records.

## Decision

Use JSON Schema 2020-12 for maintained structured contracts. The capability
schema remains at its established YAML path but contains executable JSON Schema
expressed as YAML. Reject unknown properties unless a future explicit extension
mechanism is designed. Use dependency-free Ruby self-assurance tooling to parse
and validate the repository; this tooling is not a consuming-application
runtime.

## Consequences

Contracts are testable and drift is rejected. Existing 4.x capability, finding
and execution documents require migration or historical treatment, so the
release is 5.0.0.
