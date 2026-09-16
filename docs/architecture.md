# Architecture

## Scope

This document defines the cross-cutting architecture for reproducible development, validation, the first reusable toolkit slice, its initial separate-repository consumer contract, the first pre-release, the first M6 Proxmox expansion, multiple VM network attachments, and the first reusable LXC capability. Component design and consumer workflows beyond those contracts and live infrastructure testing remain deferred to the milestones that require them.

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

The module attaches the guest-agent channel when it creates the VM, which is what lets the Ansible capability start the agent on its first run: Proxmox attaches the channel only when the setting is enabled, and a guest whose service is bound to that device cannot start it before the device exists. It never waits for agent-reported addressing and publishes no agent-reported address, so apply and refresh do not block on an agent that is not yet running. [ADR 0006](decisions/0006-guest-agent-channel-at-creation.md) records that decision, the window before the role first runs, and its sources.

The guest-agent input defaults to enabled, so the channel is present unless a consumer decides otherwise; attaching it is a consumer choice rather than a fixed behaviour. Turning it off is supported and produces a VM in which the guest agent cannot run at all, and reversing that decision costs a stop and start, because Proxmox does not hot-plug the change.

Destroy stops the VM by default rather than requesting a guest shutdown, so it depends on neither ACPI nor a running agent. **That can interrupt workloads and lose unwritten data**, and the alternative accepts a destroy that may block or time out. Neither value is free; the [module README](../tofu/modules/proxmox-linux-vm/README.md) sets out the trade-off. Nothing here changes the required plan, human review, and explicit apply workflow.

The module exposes a required, non-sensitive `connection` output of `host`, `user`, and `port`. It is a consumer composition convenience, not an Ansible dependency, and it gives OpenTofu no continuing ownership of guest access. Other public outputs are limited to non-sensitive resource identity and composition values. Exact inputs, defaults, and derivations live in the module README.

### Ansible guest-agent capability

The Ansible capability lives under `ansible/roles/qemu_guest_agent/`. It installs the `qemu-guest-agent` package and ensures that its service is running.

Whether that service can also be enabled for boot belongs to the target's packaging rather than to the role: where the unit is device-activated and static, as Debian's is, there is no installation configuration to enable. The capability's obligation is that the package is installed and the service is running once the channel is present, with boot-enabling honoured where the packaging supports it rather than claimed where it does not.

The role operates on ordinary consumer inventory. It does not read OpenTofu state or outputs, manage provider integration, create guest users, own SSH configuration, or change Proxmox resources.

Its guest contract is capability-based. [Compatibility](compatibility.md#guest-capability-contract) declares the requirements, current targets, and evidence.

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
- Ansible syntax and lint correctness, and the static package and service contract;
- composition of the connection descriptor without coupling the role to OpenTofu state; and
- the existing repository validation and publication-safety expectations.

The durable constraint is the required evidence, not a particular test mechanism; the current implementation may use provider mocking to obtain it.

This evidence does not prove live behaviour of any kind, and static or contract proof must not be represented as live compatibility evidence. [Compatibility](compatibility.md#current-evidence-level) enumerates what it does not demonstrate.

Locally decidable invalid inputs fail early and clearly. Runtime prerequisites remain visible responsibilities of their owning tools, and their failures are surfaced rather than hidden. The slice introduces no fallback orchestration, automatic recovery, blind apply, or implicit infrastructure mutation.

### Deferred from the first slice

At acceptance, the first slice deferred template lifecycle, disk mutation, linked clones, DHCP or agent-based address discovery, IPv6, VLAN inputs, multiple network interfaces, LXC, HA, generated inventory, automatic Task wiring, live infrastructure tests, runtime distribution validation, and release behavior. Its cross-component consumer and release contracts are defined separately below, and the optional single-NIC access-VLAN contract selected for M6, the later multiple-attachment contract, and the separate first LXC capability are defined later without changing first-slice ownership.

## Initial separate-repository consumer contract

The canonical coordinated M4 workflow consumes the OpenTofu module and Ansible role through one consumer-owned toolkit checkout at one immutable full commit SHA, as accepted in [ADR 0007](decisions/0007-single-revision-consumer-contract.md). The consumer's source-controlled material must identify that revision exactly.

The checkout mechanism and placement are consumer choices. A Git submodule pinned to the full SHA, vendored content with source and revision provenance recorded in source control, or another consumer-owned fetch mechanism whose source-controlled declaration reproduces the same full SHA can satisfy the contract. A path such as `vendor/homelab-iac-toolkit/` is a documentation convention, not a toolkit interface.

Both components resolve from that same checkout:

- OpenTofu uses a local source path to `tofu/modules/proxmox-linux-vm/`; and
- Ansible uses an ordinary `roles_path` containing the checkout's `ansible/roles/` directory.

Independent remote Git references can remain valid for component-only consumption, but they are not the canonical coordinated workflow because separate references can drift. OpenTofu, Ansible, and Task do not acquire, update, synchronize, or select the toolkit revision. The consumer owns acquisition, placement, updates, and any credentials needed to obtain the checkout.

### Canonical consumer flow

One minimal public example represents the structure of a separate consumer repository. It demonstrates this sequence:

1. Establish the consumer-owned toolkit checkout at the source-controlled full commit SHA.
2. Reference the OpenTofu module through a local path in that checkout.
3. Review the declared configuration, run `tofu plan`, review the plan, and run an explicit `tofu apply` only after that human review.
4. Compose ordinary Ansible inventory under consumer control by explicitly mapping the module's required non-sensitive `connection` descriptor into `ansible_host`, `ansible_user`, and `ansible_port`.
5. Run an ordinary Ansible play that invokes the `qemu_guest_agent` role from the same checkout.

The example demonstrates that mapping with fictional values, while the consumer performs it manually from reviewed output or equivalent consumer-owned configuration. The example does not read OpenTofu state, generate inventory, wire outputs automatically, or add Task orchestration. It must not suggest that copying the example makes an unattended apply safe.

The example is copyable and syntactically valid but deliberately not deployment-ready. It uses fictional or standards-reserved values when concrete values aid parsing or understanding. Where no public value can be both safe and meaningful, it exposes an explicit input boundary or documents what the consumer must supply; syntactically invalid placeholder tokens must not stand in for consumer ownership.

### Configuration and secrets boundary

Consumers own all concrete OpenTofu inputs, provider and backend configuration, state custody, Ansible inventory and authentication, and environment-specific values. Provider credentials and endpoints must not pass through the reusable module or appear in the public example. Consumers supply them at runtime using a provider-supported, consumer-controlled mechanism; exact provider environment-variable names and authentication choices are provider documentation rather than toolkit interfaces.

SSH private keys and other Ansible authentication material remain outside the public example and public inventory. The toolkit adds no secret loader, credential broker, decryption orchestration, or custom authentication abstraction.

The canonical example declares no backend. Its documentation must state that this omission is not a recommendation to use local state for a real deployment. A consumer must choose its backend and state-custody policy before real use.

SOPS and age remain the canonical interface when a toolkit-supported workflow requires encrypted secrets committed to source control. They are explicitly deferred from the initial M4 workflow because that flow requires no version-controlled encrypted secret document. Runtime-only credentials may remain outside Git and use native consumer-controlled mechanisms.

Real encrypted secret material, its recipients, and the decryption identities that open it are all consumer-owned, and none of them appears in the public toolkit. They are not, however, kept the same way. Encrypted material and the recipient list it was encrypted to are committable, and committing them to a consumer's own repository is the point of the interface. A decryption identity is a private key, and a private key kept beside the ciphertext it opens is not protecting anything: identities stay out of source control, on the systems that need them, distributed by whatever means the consumer already uses for private keys. Choosing that means is the consumer's, and the toolkit adds no mechanism for it.

### Validation and live-testing boundary

Normal public validation remains credential-free and must prove at minimum that:

- the example is syntactically valid and passes applicable static validation;
- its local module source and Ansible `roles_path` resolve through the same represented toolkit checkout;
- its fictional configuration conforms to the accepted public interfaces;
- the `connection` descriptor maps explicitly into ordinary Ansible inventory;
- it introduces no state reading, generated inventory, secret handling, backend access, automatic acquisition, or deployment orchestration; and
- existing repository validation and publication-safety checks continue to pass.

Validation may construct or use a credential-free repository fixture representing the shared pinned checkout. It does not have to reproduce a consumer's acquisition mechanism, and it must not introduce a second canonical consumption model for CI convenience. Submodule initialization, vendoring automation, or consumer-specific fetch tooling belongs in normal public CI only if a later accepted example owns that mechanism.

Public validation does not establish successful Proxmox provisioning, cloud-init behavior, SSH connectivity, Ansible convergence or idempotency, `qemu-guest-agent` runtime behavior, shutdown, reboot, backup, stop or destroy behavior, or compatibility with a live consumer environment. Consumer-run infrastructure tests remain outside the toolkit's normal evidence contract.

Toolkit-owned live testing is deferred. Any future live test must be isolated from normal public CI, explicitly opt-in, and Architecture-reviewed with credential custody, trusted triggers, infrastructure ownership, cleanup, failure handling, and cost responsibility defined before implementation. A new ADR is required when that design changes a durable security, lifecycle-ownership, compatibility, or validation boundary. Implementation details within an accepted design, such as its runner, schedule, or trigger mechanics, may change without a new ADR when those boundaries remain unchanged.

## First pre-release contract

The first public version is `v0.1.0-alpha.1`: a GitHub pre-release for evaluation and early consumers. It publishes source only from one already-merged commit on `main`, as accepted in [ADR 0008](decisions/0008-first-pre-release-contract.md). The release consists of an immutable tag, a GitHub Release, and GitHub-provided source archives. It introduces no custom artifact, package registry, container registry, or automated publisher.

The version tag is the human-facing release identity, not the coordinated consumer reference. The release record states the exact full commit SHA, and consumers continue to record that SHA in their own source-controlled checkout declaration under [ADR 0007](decisions/0007-single-revision-consumer-contract.md). Both components therefore remain selected by one immutable revision. The tag must never become a movable convenience alias.

Repository release immutability must be enabled before publication. Once published, the tag is locked to its selected commit and release assets cannot be replaced or deleted; the release title and notes may still receive editorial, non-semantic corrections. A substantive source, compatibility, migration, or artifact correction requires a new version rather than a moved tag, replaced content, rewritten source snapshot, or deleted-and-recreated release.

### Release ownership and evidence

Publication is an explicit maintainer operation outside normal public CI. It uses maintainer GitHub authorization and must not give normal CI a release credential, elevated write permission, or privileged path for untrusted pull-request code. Normal validation remains credential-free and non-destructive, and publication changes none of the lifecycle boundaries in this document.

One exact release-candidate SHA must pass the required gate from a clean checkout. The evidence includes complete repository validation, all required or otherwise applicable GitHub checks produced under the accepted trigger model, publication-safety validation, and secret scanning. A missing check that should apply is not success, but Architecture does not require a check run that the accepted CI trigger model does not produce. The completion record identifies the candidate SHA and the actual evidence used.

The detailed candidate, draft, review, publication, verification, and correction rules are in [Release policy](release-policy.md). That policy defines outcomes and evidence rather than duplicating the commands, job names, versions, or configuration owned by [Local validation](validation.md), repository tooling, and GitHub Actions.

### Compatibility, change, and upgrade boundaries

The release inherits only the compatibility evidence recorded at its commit. [Compatibility](compatibility.md) at that commit is the authoritative compatibility snapshot; executable source-controlled declarations remain authoritative for machine-consumable constraints. Static, mocked, and credential-free checks do not become live Proxmox or guest-runtime evidence because a release is published.

The committed changelog records notable consumer-facing change history, while release notes summarize and link to that history and the released compatibility snapshot. The initial release states that no migration from an earlier toolkit release exists. Later upgrades remain deliberate consumer actions: review the target change and compatibility information, update the source-controlled full-SHA pin, plan, review, and apply explicitly when infrastructure changes are intended. The toolkit does not update consumer checkouts, configuration, state, inventories, or provider constraints automatically.

`v0.1.0-alpha.1` makes no stable-interface, support-duration, maintenance-line, LTS, response-time, release-cadence, or 1.0 commitment. Later releases require new semantic-version identifiers and must document breaking changes and required migration actions before publication.

## First M6 Proxmox expansion

The first implementable M6 expansion defines optional consumer-controlled access-VLAN tagging for the existing single network attachment of `tofu/modules/proxmox-linux-vm/`, as accepted in [ADR 0009](decisions/0009-first-m6-vlan-expansion.md). Its implementation remains on the existing `proxmox_virtual_environment_vm` resource at the existing module resource address and introduces no alternate or parallel VM lifecycle.

### VLAN interface and ownership

The public input is `network_vlan_id`, with nullable-integer semantics and a default of `null`. `null` is the only public value meaning untagged; it does not disable the network attachment. A tagged value must be a whole number from `1` through `4094`; `0`, negative values, fractional values, and values above `4094` fail before apply. The provider's internal zero sentinel is not a toolkit input value.

The value applies one access VLAN tag to the VM's existing single Proxmox network attachment. It does not create or manage VLANs, configure a VLAN-aware bridge, expose trunk semantics, configure switching or routing, or configure a VLAN interface inside the guest.

OpenTofu continues to own the existing VM network attachment and its optional VLAN tag. The consumer owns bridge selection, VLAN selection, the pre-existing Proxmox bridge configuration, upstream switching, routing, and consistency between the selected VLAN and the declared static IPv4 settings. Ansible gains no guest-network ownership from this capability.

The VLAN increment itself adds no network attachment. Its bridge, static IPv4, gateway, DNS, and required `connection` contracts remain unchanged. The connection descriptor remains declared bootstrap metadata and is not evidence of reachability.

### VLAN lifecycle and evidence

Adding, changing, or removing `network_vlan_id` must update the existing VM and network attachment in place. A provider behavior that plans VM replacement for a VLAN-only change is a compatibility regression: the toolkit must not silently accept the replacement or weaken this lifecycle contract, and adoption remains blocked until Architecture reviews the change.

Credential-free module and mock-provider tests must prove the public input contract, mapping to the existing single `network_device`, preservation of the existing module resource address, unchanged networking and connection interfaces, exclusions, and locally decidable validation. Those tests may not by themselves claim that the provider updates the VM in place.

Before implementation receives an Architecture `ACCEPT` verdict, its pull request must record reliable provider-level evidence for the exact locked `bpg/proxmox` build showing that `network_device.vlan_id` exists, is mutable rather than replacement-forcing, and preserves the existing VM resource for untagged-to-tagged, tagged-to-tagged, and tagged-to-untagged transitions. The record identifies the provider build and source revision where applicable, what was inspected or executed, and why it establishes the claim. A credential-free real-provider plan, pinned provider schema and implementation inspection, enabled upstream tests, or equivalent Architecture-reviewed evidence may satisfy the gate; Architecture requires the evidence, not one permanent mechanism. Provider upgrades must re-evaluate it.

On the evidenced PVE update path, every VLAN-tag change detaches and re-attaches the virtual link and signals link-down to the guest, so a link interruption is expected even when the external network is configured correctly. Whether connectivity returns depends on the consumer-owned bridge, selected VLAN, upstream switching, routing, and static guest configuration. Public validation does not prove successful live PVE application, guest reachability, uninterrupted SSH, or zero-downtime updates.

VLAN trunks, DHCP, IPv6, bridge discovery or management, network orchestration, private topology, and guest-network configuration remain outside this increment. Multiple network attachments are defined separately [below](#multiple-vm-network-attachments).

### Blocked data-disk need

Additional persistent VM data disks are a demonstrated consumer need, but the current supported provider path does not establish safe management of additional disks while preserving template-inherited disks. [The blocked Architecture record](https://github.com/mlznlv/homelab-iac-toolkit/issues/80) retains the exact provider evidence and unblock condition. The existing module must not be redesigned around the experimental cloned-VM resource family, and no future disk interface or migration mechanism is pre-designed while that blocker remains.

## Multiple VM network attachments

The Linux VM capability supports additional network attachments after its existing primary attachment, as accepted in [ADR 0011](decisions/0011-multiple-vm-network-attachments.md). They are part of `tofu/modules/proxmox-linux-vm/` and the existing `proxmox_virtual_environment_vm` resource at its existing module resource address; no module, resource family, or parallel VM lifecycle is introduced.

### Attachment identity and interface

The primary attachment is the existing one: its bridge, optional access VLAN, static IPv4 address, gateway, and the global DNS servers keep their accepted inputs, defaults, and meaning. It is always Proxmox device slot `net0` and cloud-init IP configuration `0`. A configuration that declares no additional attachment plans exactly as it did before.

Additional attachments are optional and none exist by default. The consumer declares them in an explicit order, and an attachment's identity is its position: the first additional attachment is slot `net1`, the next `net2`, and so on, with the same index for its cloud-init IP configuration. The pinned provider expresses network devices and cloud-init addressing only as contiguous positional lists, so no identity other than position can be represented. The public interface must make that order explicit and consumer-controlled; it must not derive order implicitly, for example by sorting keys, because inserting a key would silently re-map every later slot.

At most eight attachments are supported in total, the primary included. The provider accepts at most eight cloud-init IP configurations, and a slot beyond them could not be addressed the same way as the others.

Each additional attachment:

- requires a consumer-selected bridge;
- accepts an optional access VLAN with exactly the [VLAN contract](#vlan-interface-and-ownership) of the primary attachment;
- accepts an optional static IPv4 address in CIDR notation, and no gateway; and
- accepts an optional MAC address.

Only the primary attachment carries a gateway. A gateway on another attachment would give the guest several default routes, and choosing between them is routing policy inside the guest, which this capability does not own. An additional attachment declared without an address is given no cloud-init IP configuration of its own, and the network data Proxmox generates describes only the interfaces that have one; whether and how the guest configures it is guest configuration. That describes what the module declares for a slot, not what a slot that has carried an address still contains, which [retained IP configuration](#retained-ip-configuration) sets out.

Locally decidable invalid values fail before apply, including more than eight attachments, a malformed address, the same address on two attachments, a malformed or multicast MAC address, and a VLAN outside the accepted range.

### MAC addresses and guest interface identity

When an attachment declares no MAC address, Proxmox assigns one when the device is created. A declared MAC address is used as given. The module publishes every attachment's MAC address, in slot order, as a non-sensitive output, because it is resource identity a consumer may need for its own inventory or address reservations.

The MAC address is how the guest recognizes an interface: Proxmox's cloud-init network data identifies each addressed interface by its MAC address and names it `eth` followed by the slot index. Changing an attachment's MAC address therefore replaces the device the guest sees; on a running VM Proxmox hot-unplugs the old device and plugs a new one.

### Ownership and connection

OpenTofu owns every network attachment, its optional tag, its declared MAC address, and its declared static address. The consumer owns bridge and VLAN selection, the pre-existing bridge configuration, upstream switching, routing, address allocation, and consistency between each attachment's network and its address. Ansible gains no guest-network ownership.

The required `connection` output is unchanged. It is derived only from the primary attachment's declared address, and additional attachments never alter it.

### Attachment lifecycle

No attachment change may replace the VM. A provider behavior that plans replacement for one is a compatibility regression, and adoption is blocked pending Architecture review.

- **Adding an attachment after the last one** updates the VM in place and plugs the new device.
- **Removing the last additional attachment** updates the VM in place and unplugs its device.
- **Changing an attachment's bridge or VLAN** updates it in place with the link interruption described for [VLAN changes](#vlan-lifecycle-and-evidence).
- **Changing an attachment's MAC address** updates it in place by replacing the device the guest sees.
- **Removing or reordering any attachment other than the last** re-maps every later slot in place: each later slot takes the next attachment's bridge, VLAN, address, and declared MAC address, so every later interface changes identity or network. This is disruptive, and the module cannot detect it before apply, because input validation cannot see the prior configuration. The module documents it; a consumer that needs later interfaces to stay stable removes attachments from the end.

Any change to an attachment's declared address, including adding or removing an addressed attachment, changes the cloud-init network data the VM boots with. Proxmox derives the cloud-init instance identifier from a digest of the generated user and network data, so the identifier changes too. On the pinned provider an initialization change rebuilds the cloud-init drive and, by default, reboots a running VM. On that boot cloud-init treats the guest as a new instance: it re-applies network configuration, which it otherwise applies only on a new instance, and re-runs its per-instance modules, including the SSH module, which deletes and regenerates the guest's SSH host keys unless the template's cloud-init configuration turns that off. The same consequence already applies to the primary attachment's static address, and a consumer should expect a reboot and a changed host key after any addressing change. Adding or removing an unaddressed attachment does not change the cloud-init network data.

### Retained IP configuration

The pinned provider emits a cloud-init IP configuration only for attachments that declare one, and sends no deletion for one that disappears: its update request simply omits the empty entry. The retired `ipconfig` stays in the Proxmox VM configuration, and Proxmox's cloud-init generator emits network data for every slot that still has one, matched to the MAC address the device now in that slot carries.

The capability therefore does not promise that a slot stops being addressed. Removing an addressed attachment, or making one addressless, leaves its retired configuration behind, and a later attachment at that slot can boot with the retired address. Clearing it is outside this capability: a consumer who needs it gone edits the VM configuration in Proxmox or replaces the VM.

Two limits follow. An addressless attachment is guaranteed to receive no cloud-init configuration only at a slot that has never carried one. Reusing a slot whose retired configuration still exists is not a supported way to reach an unconfigured interface. The module documents both rather than implying that removal clears anything.

### Attachment validation and evidence

Credential-free module and mock-provider tests must prove that a configuration without additional attachments is unchanged; the slot order and index of every declared attachment; per-attachment bridge, VLAN, address, and MAC mapping; that an attachment declared without an address contributes no cloud-init IP configuration; that only the primary attachment carries a gateway; the eight-attachment limit and other locally decidable validation; the MAC output; the unchanged `connection` output and module resource address; and the exclusions below. Those tests may not by themselves claim that the provider updates the VM in place.

Before implementation receives an Architecture `ACCEPT` verdict, its pull request must record provider-level evidence for the exact locked `bpg/proxmox` build showing no VM replacement when an attachment is added after the last one, the last additional attachment is removed, an additional attachment's bridge, VLAN, address, or MAC address changes, and a non-final attachment is removed. For each, the record states how the device list, MAC addresses, and cloud-init IP configurations are planned, including that a retired configuration is neither emptied nor deleted, which is what the [retained IP configuration](#retained-ip-configuration) boundary rests on. As for [the VLAN evidence gate](#vlan-lifecycle-and-evidence), Architecture requires the evidence, not one permanent mechanism, and provider upgrades must re-evaluate it.

Public validation does not prove that devices hot-plug or unplug successfully, that a guest names, configures, or brings up an interface, that cloud-init re-applies configuration or regenerates host keys on a given template, reachability through any attachment, or routing between attachments.

DHCP and IPv6 on any attachment, gateways or routes on additional attachments, VLAN trunks, NIC models, firewall, MTU, rate limit, queue, and link-state settings, bridge discovery or management, network orchestration, and guest-network configuration remain deferred. Separate DHCP and IPv6 decisions must consume, not redefine, this decision's slot identity, primary-attachment connection source, eight-configuration limit, and addressing-change lifecycle.

## First reusable LXC capability

The first reusable Proxmox LXC capability creates one unprivileged Debian container from a consumer-supplied container template, as accepted in [ADR 0010](decisions/0010-first-reusable-lxc-capability.md). It is a separate component from the Linux VM module. It shares the PVE 9.x target and the `bpg/proxmox` provider line, and assumes nothing else from the VM contract: not its resource family, clone model, bootstrap mechanism, or connection derivation.

### Container interface and ownership

The capability manages one `proxmox_virtual_environment_container` resource under `tofu/modules/proxmox-linux-container/`. It:

- creates the container from a consumer-supplied container template volume that already exists on Proxmox storage, and does not clone an existing container;
- declares the Debian operating-system type rather than inheriting the provider's `unmanaged` default, because Proxmox configures the network, hostname, DNS, and root SSH keys inside a container only through a managed operating-system type;
- always creates an unprivileged container;
- enables the nesting feature by default, lets the consumer disable it, and exposes no other container feature;
- declares start-on-boot explicitly rather than inheriting the provider's default, and declares it so that a container starts again when its host boots;
- accepts a consumer-owned container name, which the module sets as the provider's `initialization.hostname` and which must therefore be a valid DNS name, and a consumer-owned optional identifier, node, template, root-filesystem datastore and size, CPU cores, and dedicated memory;
- accepts a port value, defaulting to `22`, published in `connection` as metadata only, as the VM module's `ssh_port` is;
- attaches exactly one network interface to one consumer-selected bridge, with a static IPv4 CIDR, gateway, and at least one DNS server; and
- installs consumer-supplied SSH public keys for the container's root account as creation-time bootstrap only, and sets no password.

DNS servers are required rather than optional, because Proxmox otherwise copies the node's own resolver configuration into the container, and a node's resolvers are environment detail that a reusable component must not adopt silently.

OpenTofu owns the container resource, its single network interface, and its root filesystem. The consumer owns the node, storage, bridge, addresses, sizing, and identifiers; acquiring and maintaining the template, including an SSH server that accepts public-key login for root; the private half of the bootstrap keys; and everything configured inside the container after creation. The bootstrap keys give OpenTofu no continuing ownership of root's authorized keys, users, or SSH configuration.

The module exposes a required, non-sensitive `connection` output of `host`, `user`, and `port`. `host` is the declared IPv4 address without its prefix, `user` is `root`, and `port` is connection metadata that defaults to `22` and configures nothing. The module publishes no address the provider reads back from the running container, and `connection` never depends on one. The provider's own read path does read interfaces: on the pinned build, reading a started container that has an interface waits up to ten seconds for one to report an address, and treats a timeout as a warning rather than an error. Omitting its wait-for-IP block, as the module does, selects waiting for any address rather than none. That bounded, non-fatal wait belongs to the provider; the module neither configures nor consumes its result, so a refresh can take up to ten seconds longer while nothing in the module's contract changes. Other public outputs are limited to non-sensitive resource identity.

The consumer composes inventory from that output or from independent values and runs its own guest configuration. No Ansible role is added, and the `qemu_guest_agent` role does not apply: a container has no QEMU guest-agent channel.

### Container lifecycle

Changing the bridge, static IPv4 address, gateway, DNS servers, container name, or dedicated memory must update the existing container in place. On the pinned provider a running container is rebooted to apply any of those, so an interruption is expected. Changing CPU cores also updates in place, and the provider requests no reboot for it. Growing the root filesystem must also update in place.

Enabling or disabling nesting updates the configuration in place, but the pinned provider requests no restart for a feature change. The container keeps running under its previous profile until something else restarts it, so the capability documents the change as taking effect at next start rather than immediately.

The following replace the container, destroying it and its root filesystem and creating a new one: changing the template, the root-filesystem datastore, the node, or the identifier, and shrinking the root filesystem, which Proxmox cannot do in place. The module documents each as destructive and never hides the replacement; the consumer's plan review is the control. A shrink cannot be caught by input validation, which cannot see the prior size, so it reaches the consumer as a planned replacement rather than a plan-time error.

Changing the bootstrap SSH keys after creation must not replace the container. The pinned provider marks root's keys as replacement-forcing, so the module keeps that behaviour from reaching consumers by ignoring later changes to the bootstrap key attribute on its own resource. A key change therefore produces no plan at all: the existing container and its authorized keys are untouched, and rotating root's keys is guest configuration.

Destroy asks Proxmox to shut the container down with forcing already enabled, and with a timeout five seconds shorter than the provider's delete timeout, so under the defaults the guest gets 55 seconds before Proxmox stops it and the container is deleted. That can interrupt workloads and lose unwritten data. The module exposes no timeout or destroy-policy input in this slice; a consumer-controlled destroy policy like the VM module's remains deferred.

Before implementation receives an Architecture `ACCEPT` verdict, its pull request must record provider-level evidence for the exact locked `bpg/proxmox` build showing that: the Debian operating-system type, unprivileged mode, and the declared start-on-boot value reach the create request; a bootstrap-key change plans nothing at all under the module's declared handling, rather than the replacement the provider would otherwise force; root-filesystem growth updates in place while shrinking, a datastore change, a template change, a node change, and an identifier change plan replacement; network, DNS, name, and memory changes update in place; a CPU-cores change updates in place; and enabling or disabling nesting updates the container in place without a restart. As for [the VLAN evidence gate](#vlan-lifecycle-and-evidence), Architecture requires the evidence, not one permanent mechanism, and provider upgrades must re-evaluate it.

### Container validation and non-claims

Credential-free module and mock-provider tests must prove the required inputs and locally decidable validation; creation from a template rather than a clone; the Debian operating-system type, unprivileged mode, the nesting default and override, and the explicit start-on-boot declaration; the single network interface and its static addressing; bootstrap keys without a password; the root-filesystem datastore and size; the `connection` output and its derivation; and the exclusions below. Those tests cannot by themselves establish the provider's replacement behavior.

Public validation does not prove container creation, template compatibility, in-container network configuration, SSH reachability, whether nesting is sufficient for a guest's init system, reboot, shutdown, forced stop, or destroy behavior.

Cloning, privileged containers, other container features, mount points, bind mounts, device passthrough, ID mapping, multiple network interfaces, VLAN tags, DHCP, IPv6, passwords, non-root bootstrap accounts, other distributions, a consumer override for start-on-boot, startup ordering, protection, HA, timeout and destroy-policy inputs, template acquisition, container-specific Ansible roles, and examples remain deferred.

## Constraints for future components

Future components must:

- expose explicit inputs and outputs;
- avoid private-environment assumptions and hidden conventions;
- preserve lifecycle ownership;
- use fictional or standards-reserved example values;
- document destructive or replacement-sensitive behavior;
- remain usable by unrelated consumers;
- add abstractions only for demonstrated reusable needs.

Provider, module, role, platform, and validation decisions beyond the first slice remain deferred. Consumer workflows beyond the initial contract, live testing, broader compatibility commitments, future release cadence, and stable-release guarantees also remain deferred.
