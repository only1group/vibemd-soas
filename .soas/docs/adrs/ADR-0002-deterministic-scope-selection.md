# ADR-0002: Deterministic signal-based capability selection

- Status: Accepted
- Date: 2026-07-23

## Context

Fixed journey lists omitted material domains, while running all capabilities
would be indiscriminate.

## Decision

Keep journeys as capability compositions. Resolve a baseline plus a
version-controlled signal-to-capability matrix, then add transitive
dependencies. Record selected and excluded decisions with evidence, reason and
uncertainty.

## Consequences

Selection is reproducible and minimal for declared signals. The matrix is a
public assurance policy and must be fixture-tested when changed.
