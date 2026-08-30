# Architecture

## Scope

This document defines the minimum cross-cutting architecture required for reproducible development and validation. Component-specific, consumer, and release design remains deferred to the milestones that require it.

## Repository boundary

The public toolkit owns reusable source, public interfaces, documentation, validation, developer tooling, and sanitized examples. It must remain usable without access to a particular private deployment repository.

Consumers own environment-specific composition and inventory, concrete provider configuration, credentials, endpoints, backend configuration, state custody, topology, resource sizing, identities, and real secrets.

The toolkit may later define supported provider requirements, version constraints, and reusable provider-facing interfaces through approved Architecture. It does not own a consumer's concrete provider or backend configuration.

The public toolkit and its public artifacts must not contain real deployment data, credentials, secrets, decryption identities, generated state, or sensitive plans.

## Lifecycle ownership

| Concern | Owner |
| --- | --- |
| Proxmox resource lifecycle and infrastructure dependencies | OpenTofu |
| Guest operating-system and service configuration | Ansible |
| Developer workflow orchestration | Task |
| Secrets-encryption interface | SOPS and age |
| Durable source, documentation, and decisions | Git |
| Public validation | Repository tooling and GitHub Actions |

A concern has one lifecycle owner. Supporting scripts and workflow tools may invoke the owner but must not create a competing source of state or configuration.

OpenTofu may perform the minimum creation-time bootstrap needed to make a guest manageable. Continuing guest configuration belongs to Ansible. Ansible must not create or destroy Proxmox resources.

## Contributor control plane

The contributor control plane consists of:

- a repository-owned Dev Container as the canonical development environment;
- authoritative, source-controlled tool-version declarations independent of the container implementation;
- documented direct validation commands;
- a transparent Task interface for discovery and aggregation;
- repository-owned validation configuration and small helpers where necessary;
- GitHub Actions enforcing equivalent validation.

Assistant-specific configuration may improve contributor safety, but it is optional. It must reference, not replace, repository architecture and workflow documentation.

## Validation philosophy

Normal validation is deterministic, non-destructive, and credential-free. Contributors and public CI must be able to run it without a live Proxmox environment, private inventory, secret decryption, or access to a private deployment repository.

Local and CI parity means the same check set, supported tool versions, configuration, and pass/fail semantics. It does not require identical operating environments.

Live infrastructure testing, if introduced later, requires separate Architecture and must not become a dependency of normal public CI.

## Constraints for future components

Future components must:

- expose explicit inputs and outputs;
- avoid private-environment assumptions and hidden conventions;
- preserve lifecycle ownership;
- use fictional or standards-reserved example values;
- document destructive or replacement-sensitive behavior;
- remain usable by unrelated consumers;
- add abstractions only for demonstrated reusable needs.

Provider selection, module interfaces, Ansible packaging, consumer examples, live testing, compatibility, and release design remain deferred.
