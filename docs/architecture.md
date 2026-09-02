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

The first slice is a coordinated OpenTofu VM capability and Ansible guest-agent capability, as accepted in [ADR 0006](decisions/0006-guest-agent-channel-at-creation.md). The components are independently usable and have no direct runtime dependency on one another.

### OpenTofu VM capability

The OpenTofu capability manages one Proxmox Linux VM under `tofu/modules/proxmox-linux-vm/`. It:

- uses the `bpg/proxmox` provider without configuring it for the consumer;
- creates a full clone from a consumer-supplied cloud-init template;
- accepts consumer-owned VM identity, target and template identifiers, target datastore, CPU and memory sizing, and one network bridge;
- applies a consumer-supplied static IPv4 CIDR, gateway, and DNS servers;
- uses a consumer-supplied username and SSH public keys only to bootstrap initial guest access;
- accepts an `ssh_port` value, defaulting to `22`, only as connection metadata; and
- inherits the source template's disk layout rather than managing disk changes in this slice.

The bootstrap username and public keys do not give OpenTofu continuing ownership of guest users, authorized keys, or SSH configuration. Those remain Ansible or consumer concerns after creation.

The module attaches the guest-agent channel when it creates the VM, and its guest-agent input defaults to enabled. The channel therefore exists before any guest configuration runs, which is what lets the Ansible capability start the agent on its first run: Proxmox attaches the channel only when the setting is enabled, and a guest whose service is bound to that device cannot start it before the device exists.

The module never waits for agent-reported addressing. Provider IP waiting is disabled unconditionally, so apply and refresh do not block on an agent that is not yet installed or running, and creation and access use the declared static address. The module publishes no agent-reported address.

A consumer may turn the channel off. That produces a VM in which the guest agent cannot run, and adding the channel afterwards requires stopping and starting the VM, because Proxmox does not hot-plug the change.

Between creation and the role's first run, the VM has a channel with nothing behind it. Shutdown and reboot fall back to ACPI after a short probe rather than hanging, a backup taken in that window skips the guest filesystem freeze and is crash-consistent, and anything that queries the agent reports it unavailable. [ADR 0006](decisions/0006-guest-agent-channel-at-creation.md) records that window and its sources.

The module exposes a `stop_on_destroy` input that defaults to `true`. With that default, the provider stops the VM rather than requesting a graceful shutdown before destroying it, avoiding reliance on ACPI or on a guest agent that may not yet be running. A stop can interrupt guest workloads and lose unwritten data. A consumer may set the input to `false` only when the consumer accepts reliance on reliable guest shutdown through ACPI or an enabled guest agent, including the risk that destroy can time out or remain blocked when shutdown fails. This setting does not change the required plan, human review, and explicit apply workflow.

The module exposes a required, non-sensitive `connection` output containing `host`, `user`, and `port`. `host` is the declared static IPv4 address without its prefix, `user` is the bootstrap username, and `port` is the `ssh_port` metadata value. The module does not configure the guest's SSH port, and the descriptor does not give OpenTofu continuing ownership of guest access. It is a consumer composition convenience, not an Ansible dependency. Other public outputs are limited to non-sensitive resource identity and composition values required by the module.

### Ansible guest-agent capability

The Ansible capability lives under `ansible/roles/qemu_guest_agent/`. It installs the `qemu-guest-agent` package and ensures that its service is running.

Whether that service can also be enabled for boot belongs to the target's packaging rather than to the role. Where the unit is device-activated and static, as Debian's is, it is started from a udev rule when the channel appears and carries no installation configuration to enable; `systemctl is-enabled` reports `static`, which Ansible treats as already enabled. The capability's obligation is therefore that the package is installed and the service is running once the channel is present, and that enabling at boot is honoured where the packaging supports it rather than claimed where it does not.

The role operates on ordinary consumer inventory. It does not read OpenTofu state or outputs, manage provider integration, create guest users, own SSH configuration, or change Proxmox resources.

Its guest contract is capability-based: supported Python and Ansible requirements, APT package management, systemd service management, and availability of the expected package and service. Current targets and evidence are declared in [Compatibility](compatibility.md).

### Consumer-controlled flow

The expected composition is:

1. The consumer applies the OpenTofu module with static addressing and the guest-agent channel present.
2. The consumer composes inventory from independent values or the module's required non-sensitive `connection` output.
3. The consumer runs the Ansible role to install the guest agent and bring its service up.

No later reconciliation is required for the guest agent: the channel it needs was there from creation, and the provider never waited for it.

The consumer owns this ordering and all credentials, inventory, provider and backend configuration, templates, topology, sizing, private keys, and orchestration. Task does not wire the components together automatically.

### Validation evidence

Credential-free contract validation must prove at minimum:

- required module inputs and locally decidable input validation;
- full-clone configuration and declared static addressing behavior;
- the guest-agent channel attached at creation, and provider IP waiting disabled;
- `stop_on_destroy` defaulting to `true` and an explicit `false` override reaching the provider resource;
- the required `connection` output and its declared `host`, `user`, and `port` derivation;
- Ansible syntax and lint correctness;
- the static package and service contract;
- composition of the connection descriptor without coupling the role to OpenTofu state; and
- the existing repository validation and publication-safety expectations.

The current implementation may use OpenTofu provider mocking to obtain module evidence, but the required evidence rather than a particular test mechanism is the durable constraint.

This evidence does not prove live PVE plan, apply, or destroy behavior; graceful guest shutdown or reliable forced stop; template cloning or cloud-init bootstrapping; SSH connectivity; Ansible convergence or idempotency on a real guest; or successful provider-side guest-agent integration. Static and contract proof must not be represented as live compatibility evidence.

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
