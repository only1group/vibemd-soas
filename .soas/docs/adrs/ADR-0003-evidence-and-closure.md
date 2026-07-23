# ADR-0003: Evidence fitness and explicit closure independence

- Status: Accepted
- Date: 2026-07-23

## Context

An absolute evidence hierarchy could prefer narrow stale tests. Closure did not
define independence, especially for AI agents sharing context.

## Decision

Assess evidence fitness across provenance, scope match, freshness,
independence, reproducibility, integrity, completeness and corroboration.
Record conflicts instead of averaging them. Identify implementer and verifier,
classify independence and disclose self-verification. Agents sharing a session
or context are not independent.

## Consequences

Evidence judgments remain explainable rather than falsely numeric. Some
findings cannot be independently closed when a suitable verifier is
unavailable; they must retain a disclosed limitation.
