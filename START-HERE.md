# Legal Notice

Before using SOAS, read `DISCLAIMER.md` and `LICENSE`.

Use of SOAS constitutes acceptance of the disclaimer and licence terms.

# Start Here — VibeMD SOAS

VibeMD SOAS is a repository-local instruction system for an AI-enabled IDE or CLI assistant.
It does not require a separate application, server, database or runtime.

## Five-minute start

1. Copy the `.soas` package into the root of the application repository.
2. Open the repository in an AI-enabled IDE or CLI assistant.
3. Tell the assistant to read `.soas/SOAS.md`.
4. Choose one of the two primary paths below.
5. Allow SOAS to create `soas-output/` in the application repository.

### New or less-experienced engineer

Use:

> Read `.soas/SOAS.md`. Use the Guided Engineer profile. Start the Greenfield Build Journey and coach me from idea to production. Explain decisions in plain English, recommend safe defaults, and do not let me skip material engineering, security, UX, testing, documentation or operational work.

### Experienced engineer

Use:

> Read `.soas/SOAS.md`. Use the Lead Peer profile. Reconstruct this system from repository evidence, challenge my assumptions, identify material risks and trade-offs, and run the Lead Peer Assurance Journey. Keep explanations concise and evidence-led.

### Run one capability only

Use:

> Read `.soas/SOAS.md` and run capability `SOAS-SEC-APPLICATION` against this repository.

or:

> Read `.soas/SOAS.md` and assess whether this system can support 5,000 concurrent users. Resolve the applicable performance and resilience capabilities, record assumptions, and create a professional assurance output.

## What SOAS creates

SOAS writes controlled outputs under `soas-output/<execution-id>/`, including:

- execution manifest
- summary and detailed reports
- findings, risks, assumptions and evidence registers
- architecture decisions
- remediation and verification prompts
- closure evidence

SOAS must not silently change application code. It may propose or implement remediation only with explicit user permission.

Every execution records the assessed commit and dirty-worktree state, selected
and excluded capabilities, evidence limitations and capability outcomes.
`insufficient-evidence`, `not-executed` and `blocked` are never positive
assurance conclusions. Active testing defaults to non-destructive inspection
and requires the authorization defined in `orchestrator/active-testing-protocol.yaml`.
