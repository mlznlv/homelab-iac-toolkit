# ADR 0004: Local validation, Task, and CI security boundary

Status: Accepted.

## Decision

- Define validation in repository-owned configuration and inspectable direct
  commands, with thin Task wrappers and non-mutating aggregate validation.
- Keep local/CI checks, versions, configuration and pass/fail semantics equivalent.
- Treat public PR code as untrusted, with minimal permissions, immutable action
  references, verified downloads and no privileged execution of untrusted code.
- Exclude credentials, decryption, deployment/private access, apply/destroy and
  sensitive artifacts from normal validation; allow public downloads/link checks.
- Require separate Architecture and isolation for future live tests; never label
  static evidence as live compatibility.

## Rationale

CI-only checks leave contributors unable to reproduce failures. Shared local
commands improve review and troubleshooting without making Task a lifecycle
owner or giving public forks privileged access.

## Consequences

[Architecture](../architecture.md#validation-boundary) owns the current security
boundary; [Taskfile](../../Taskfile.yml) owns direct commands, also usable without
Task. Credentials are not persisted unless an approved workflow requires it.
Normal checks remain available without a private repository or Proxmox access.
Workflow grouping/task names can evolve without changing these decisions.

## References

- [Contributor validation](../../CONTRIBUTING.md#validate-your-change)
- [Evidence levels](../compatibility.md#current-evidence-level)
