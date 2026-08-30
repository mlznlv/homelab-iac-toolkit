# Architecture Decision Records

Architecture Decision Records document durable, cross-cutting decisions that affect repository boundaries, lifecycle ownership, contributor behavior, or public interfaces.

## Convention

- Filenames use a four-digit identifier followed by a concise title.
- Every ADR contains Status, Context, Decision, and Consequences.
- Valid statuses are `Proposed`, `Accepted`, `Rejected`, and `Superseded`.
- Proposed ADRs are not authoritative until accepted.
- The decision text of an accepted ADR is immutable.
- A later change is recorded in a new ADR that supersedes the earlier decision.
- Non-semantic corrections may be reviewed without changing the decision.
- ADRs do not duplicate roadmap sequencing or implementation specifications.

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-public-toolkit-private-deployment-boundary.md) | Public toolkit and private deployment boundary | Accepted |
| [0002](0002-lifecycle-orchestration-ownership.md) | Lifecycle and orchestration ownership | Accepted |
| [0003](0003-development-environment-tool-version-policy.md) | Development environment and tool-version policy | Accepted |
| [0004](0004-local-validation-task-ci-security-boundary.md) | Local validation, Task, and CI security boundary | Accepted |
