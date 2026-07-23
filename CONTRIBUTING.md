# Contributing to VibeMD SOAS

Thank you for contributing.

## Principles

- Preserve the instruction-native architecture.
- Prefer extending capabilities rather than duplicating them.
- Base engineering guidance on recognised authoritative standards.
- Keep jurisdiction overlays separate from the global core.
- Do not introduce industry-specific frameworks into the core package.
- Record significant architectural changes with an ADR.

## Pull Request Checklist

- Capability or journey follows the existing structure.
- `make validate` and `make test` pass from the source repository.
- YAML, JSON and schema-covered examples validate.
- Capability, journey, dependency, standards and output references resolve.
- Selection-policy changes include exact golden fixture updates.
- Documentation is updated where needed.
- Existing behaviour is preserved unless intentionally changed.
- Changes are described in the CHANGELOG.

## Versioning

VibeMD SOAS follows Semantic Versioning:

- MAJOR – incompatible capability or output contracts
- MINOR – new capabilities or significant features
- PATCH – fixes, clarifications and documentation improvements

By contributing, you agree that your contribution may be distributed under the MIT License.
