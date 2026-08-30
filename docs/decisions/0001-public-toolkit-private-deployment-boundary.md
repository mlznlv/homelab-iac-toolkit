# ADR 0001: Public toolkit and private deployment boundary

## Status

Proposed

## Context

The project must provide reusable public building blocks without publishing or depending on one concrete homelab. Environment-specific configuration, concrete provider access, state, and secrets are consumer concerns and cannot become hidden requirements of the public toolkit.

## Decision

The public toolkit owns:

- reusable OpenTofu and Ansible content;
- public interfaces, documentation, and validation;
- repository developer tooling;
- sanitized fixtures and examples;
- reusable configuration schemas when approved.

Consumers own:

- environment composition and inventories;
- concrete provider configuration, credentials, and endpoints;
- backend configuration and state custody;
- real hostnames, addresses, domains, identifiers, topology, and sizing;
- real secrets, recipients, and decryption identities;
- deployment-specific policies and workload definitions.

The toolkit may later define supported provider requirements, version constraints, and reusable provider-facing interfaces through approved Architecture. Those decisions do not transfer ownership of a consumer's concrete provider configuration, credentials, endpoints, or backend.

The public toolkit repository and its public artifacts must not contain real deployment data, credentials, secrets, decryption identities, generated state, or sensitive plans. Handling policy inside a private consumer repository remains the consumer's responsibility.

The toolkit must validate and remain understandable without access to a particular private repository. Public examples use fictional or standards-reserved values and explain how an unrelated consumer supplies equivalent configuration.

## Consequences

- Public components require explicit, reusable interfaces.
- Environment-specific defaults and hidden private-file dependencies are prohibited.
- Consumers maintain their own deployment composition and provider access.
- Sanitized examples may demonstrate interface shape but cannot serve as real deployments.
- Private deployment details cannot be used as public tests or documentation fixtures.
