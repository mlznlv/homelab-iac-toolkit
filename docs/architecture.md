# Architecture

## Scope

This document defines the cross-cutting architecture for reproducible development, validation, and the first reusable toolkit slice. Component design beyond that slice, consumer guidance, and release design remain deferred to the milestones that require them.

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

## First reusable toolkit slice

The first slice is a coordinated OpenTofu VM capability and Ansible guest-agent capability, as accepted in [ADR 0005](decisions/0005-first-reusable-toolkit-slice.md). The components are independently usable and have no direct runtime dependency on one another.

### OpenTofu VM capability

The OpenTofu capability manages one Proxmox Linux VM under `tofu/modules/proxmox-linux-vm/`. It:

- uses the `bpg/proxmox` provider without configuring it for the consumer;
- creates a full clone from a consumer-supplied cloud-init template;
- accepts consumer-owned VM identity, target and template identifiers, target datastore, CPU and memory sizing, and one network bridge;
- applies a consumer-supplied static IPv4 CIDR, gateway, and DNS servers;
- uses a consumer-supplied username and SSH public keys only to bootstrap initial guest access; and
- inherits the source template's disk layout rather than managing disk changes in this slice.

The bootstrap username and public keys do not give OpenTofu continuing ownership of guest users, authorized keys, or SSH configuration. Those remain Ansible or consumer concerns after creation.

Provider-side guest-agent integration is optional and disabled by default. A consumer may enable it only when the consumer guarantees that `qemu-guest-agent` is already installed, enabled, and running. The module never uses agent-reported addressing for initial creation or access.

Public outputs are limited to non-sensitive resource identity and composition values declared by the module. The module may expose an optional connection descriptor containing `host`, `user`, and `port`; this is a consumer convenience, not an Ansible dependency.

### Ansible guest-agent capability

The Ansible capability lives under `ansible/roles/qemu_guest_agent/`. It installs the `qemu-guest-agent` package and ensures that its systemd service is enabled and running.

The role operates on ordinary consumer inventory. It does not read OpenTofu state or outputs, manage provider integration, create guest users, own SSH configuration, or change Proxmox resources.

Its guest contract is capability-based: supported Python and Ansible requirements, APT package management, systemd service management, and availability of the expected package and service. Current targets and evidence are declared in [Compatibility](compatibility.md).

### Consumer-controlled flow

The expected composition is:

1. The consumer applies the OpenTofu module with static addressing and guest-agent integration disabled.
2. The consumer composes inventory from independent values or the module's optional non-sensitive outputs.
3. The consumer runs the Ansible role to install and enable the guest agent.
4. The consumer may enable provider-side guest-agent integration in a later OpenTofu reconciliation.

The consumer owns this ordering and all credentials, inventory, provider and backend configuration, templates, topology, sizing, private keys, and orchestration. Task does not wire the components together automatically.

### Validation evidence

Credential-free contract validation must prove at minimum:

- required module inputs and locally decidable input validation;
- full-clone configuration and declared static addressing behavior;
- provider-side guest-agent integration disabled by default;
- the module's declared public outputs;
- Ansible syntax and lint correctness;
- the static package and service contract;
- composition of optional connection values without coupling the role to OpenTofu state; and
- the existing repository validation and publication-safety expectations.

The current implementation may use OpenTofu provider mocking to obtain module evidence, but the required evidence rather than a particular test mechanism is the durable constraint.

This evidence does not prove live PVE plan, apply, or destroy behavior; template cloning or cloud-init bootstrapping; SSH connectivity; Ansible convergence or idempotency on a real guest; or successful provider-side guest-agent integration. Static and contract proof must not be represented as live compatibility evidence.

Locally decidable invalid inputs fail early and clearly. Runtime prerequisites remain visible responsibilities of their owning tools, and their failures are surfaced rather than hidden. The slice introduces no fallback orchestration, automatic recovery, blind apply, or implicit infrastructure mutation.

### Deferred from the first slice

The first slice does not design or implement template lifecycle, disk mutation, linked clones, DHCP or agent-based address discovery, IPv6, VLAN inputs, multiple network interfaces, LXC, HA, generated inventory, automatic Task wiring, live infrastructure tests, runtime distribution validation, cross-component consumer examples, or release behavior.

## Constraints for future components

Future components must:

- expose explicit inputs and outputs;
- avoid private-environment assumptions and hidden conventions;
- preserve lifecycle ownership;
- use fictional or standards-reserved example values;
- document destructive or replacement-sensitive behavior;
- remain usable by unrelated consumers;
- add abstractions only for demonstrated reusable needs.

Provider, module, role, platform, and validation decisions beyond the first slice remain deferred. Consumer examples, live testing, broader compatibility commitments, and release design also remain deferred.
