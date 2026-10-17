# ADR 0002: Lifecycle and orchestration ownership

Status: Accepted.

## Decision

- Assign Proxmox resource lifecycle and infrastructure dependencies to OpenTofu.
- Assign continuing guest OS, package, user, application and service state to Ansible.
- Permit minimum creation-time bootstrap in OpenTofu; prohibit Ansible resource
  creation/destruction and competing continuing guest ownership.
- Assign transparent workflow invocation to Task/scripts/CI without hidden state.
- Use SOPS/age for the secrets-encryption interface and Git for durable source,
  configuration, documentation and decisions; generated data is not a rival authority.

## Rationale

Several tools can mutate similar concerns. Explicit ownership prevents conflicting
state, hidden orchestration and nondeterministic behavior while preserving
independently usable components.

## Consequences

Cross-tool handoffs use explicit inputs and outputs. Supporting scripts invoke
owners instead of reproducing them. Real secrets and decryption identities remain
consumer-owned and absent from public CI. Overlapping lifecycle ownership needs
a new decision rather than an implementation shortcut.

## References

- [Ownership and dependency direction](../architecture.md#lifecycle-ownership)
- [Consumer handoff](../using.md#workflow)
