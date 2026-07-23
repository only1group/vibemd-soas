# Remediation Prompt — {{finding_id}}

Read `.soas/SOAS.md` and the referenced finding.

Implement only the agreed remediation scope. Preserve existing behaviour unless explicitly changed.
Add or update tests that prove the finding is addressed. Do not mark the finding closed.
Record changed files, commands executed, test results, assumptions and residual risks.
Identify the implementer. Then request verification under
`orchestrator/closure-protocol.yaml`; an implementer or agent sharing the same
session cannot claim independent closure.
