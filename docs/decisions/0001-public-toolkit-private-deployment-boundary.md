# ADR 0001: Public toolkit and private deployment boundary

Status: Accepted.

## Decision

- Keep reusable OpenTofu/Ansible source, interfaces, docs, tooling, validation, sanitized
  examples and approved reusable schemas in the public toolkit.
- Keep deployments, composition, inventory, provider/backend access, state, identities,
  topology, sizing, secrets and workload policy consumer-owned.
- Require the toolkit to work and validate without any private repository.
- Require public-safe source and artifacts under [Security](../../SECURITY.md); provider
  requirements/interfaces never transfer concrete access ownership.

## Rationale

Reusable infrastructure code cannot be shared safely if it embeds a particular homelab's
configuration or requires unpublished inputs. A public/private split lets unrelated consumers
reproduce and review the same components.

## Consequences

Interfaces must be explicit and examples fictional or standards-reserved. Hidden private-file
dependencies and environment-specific defaults are prohibited. Consumers maintain deployment
composition and provider access. Private deployment policy remains theirs; private data cannot
serve as public test fixtures.

## References

- [Current boundaries](../architecture.md#repository-boundary)
- [Publication rules](../../SECURITY.md#publication-boundary)
