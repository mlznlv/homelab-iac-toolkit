# Compatibility

This document is the public compatibility contract for approved reusable toolkit components. It records current platform targets and the level of evidence supporting them. At a release commit, this file is the authoritative compatibility snapshot for that release; on `main`, it may describe later unreleased changes. It is not a duplicate tool-version manifest.

Contributor tool versions remain authoritative in the declarations described by [Supported tool versions](toolchain.md). Each module's executable `required_version` and provider requirements own its consumption and provider constraints; this document records compatibility targets, evidence and limitations rather than replacing those declarations.

## Release maturity

`v0.1.0-alpha.1` is an evaluation and early-consumer pre-release. Its source identity is immutable, but its public interfaces are not yet stable and breaking changes may occur before 1.0. It creates no support-duration, maintenance-line, LTS, response-time, future release-cadence, or 1.0 commitment.

The first release inherits only the targets and evidence recorded on this page at its release commit. Publication does not promote an expected-compatible platform to a runtime-validated reference platform or turn static and mocked checks into live compatibility evidence. Release notes link to this snapshot rather than maintaining a competing compatibility table.

## OpenTofu CLI compatibility and evidence

[ADR 0016](decisions/0016-module-cli-minimum-and-evidence-policy.md) retains 1.6.0 as the intended consumer minimum for both modules. The executable constraints are in the [VM requirements](../tofu/modules/proxmox-linux-vm/versions.tf) and [LXC requirements](../tofu/modules/proxmox-linux-container/versions.tf). The contributor OpenTofu pin is a separate development/test contract, not a replacement consumption minimum. The repository's mock tests need newer test-runner features; their prerequisites neither raise the consumer minimum nor establish a supported range for the whole test suite.

**The current VM source does not meet its declared minimum.** At reviewed source `3a8553a16bcfd5a4e78957988d96f0b5fc9ab543`, fresh consuming-root initialization succeeded but validation with nullable defaults failed on 1.6.0 and 1.9.4 at the VM's identifier/VLAN guards. The same baseline passed for LXC, and both roots passed on 1.10.0 and 1.12.6. [The exact investigation record](https://github.com/mlznlv/proxmox-iac-toolkit/issues/120#issuecomment-6233199326) distinguishes these unmodified-source probes from earlier scratch-patched diagnostics. They are sampled initialization/validation results, not full feature qualification or an interval-wide guarantee.

[Correction #112](https://github.com/mlznlv/proxmox-iac-toolkit/issues/112) must be followed by fresh evidence against the final corrected, unmodified source before the retained VM minimum can be called verified. The [consumption evidence procedure](validation.md#module-consumption-compatibility-evidence) requires a calling root at the declared minimum, nullable-default checks and focused valid/invalid cases; passing normal full validation on the contributor pin is necessary but not sufficient for that claim. This policy does not itself complete the correction, change executable constraints or introduce a CI version matrix.

CLI evidence does not expand provider lifecycle or runtime claims. It qualifies only the behavior actually exercised at the recorded source, CLI and provider identities, not every version allowed by a constraint or future releases. Provider signing remediation remains separately tracked in [#111](https://github.com/mlznlv/proxmox-iac-toolkit/issues/111); a different CLI's warning behavior is not evidence that signing has been fixed.

## Proxmox VE target

The first reusable OpenTofu module supports Proxmox VE 9.x through the `bpg/proxmox` provider.

The supported PVE major is explicit and does not float when a new major is released. Adopting another major requires deliberate compatibility review, corresponding validation, and an update to this declaration and the module's executable constraints where applicable. A new ADR is required only when that review changes the durable compatibility policy or another architectural decision.

The toolkit owns the provider requirement and reusable module interface. Consumers continue to own concrete provider configuration, credentials, endpoints, backend configuration, and state.

### Optional VLAN capability

The accepted first M6 expansion defines an optional access VLAN tag for the existing single network attachment of `proxmox-linux-vm`. It does not change the PVE 9.x target, select another provider line, or introduce another provider resource family. `null` remains untagged, and tagged values are whole VLAN identifiers from `1` through `4094`.

The compatibility contract requires VLAN-only changes to preserve the existing VM resource. Before implementation is accepted, its pull request must record reliable provider-level evidence for the exact locked `bpg/proxmox` build that untagged-to-tagged, tagged-to-tagged, and tagged-to-untagged transitions are mutable rather than replacement-forcing. Provider upgrades must re-evaluate that evidence; a version that plans replacement for a VLAN-only change is blocked pending Architecture review.

The in-place behavior is the toolkit contract, while the evidence supporting it is build-specific. The repository lock identifies the exact provider build for which the toolkit has accepted evidence; a build merely allowed by the executable version constraint does not acquire that evidence until reviewed. Consumers own their root provider lock and must inspect the resulting plan before apply.

This provider-level lifecycle evidence is distinct from runtime compatibility. It does not show that a VLAN change succeeds against PVE, that a consumer's bridge or upstream network is configured correctly, or that connectivity survives the update.

### Multiple network attachments

The accepted multiple-attachment capability extends `proxmox-linux-vm` on the same PVE 9.x target, provider line, and resource. It supports at most eight attachments, identified by position, because the pinned provider represents network devices and cloud-init addressing as positional lists and accepts at most eight cloud-init IP configurations.

Its supported lifecycle is append-and-update under [ADR 0014](decisions/0014-additional-attachment-retirement-lifecycle.md), which retains ADR 0011's interface but supersedes retirement support. Initial declaration, append, and stable-slot bridge, VLAN, MAC, and static-address addition/change must preserve the VM and unchanged primary configuration and MAC. Existing slots retain their order and the count must not shrink. Removal of any attachment or address, clearing, reorder, and removal/re-addition are unsupported; the restriction is not automatically enforceable from current inputs and requires consumer plan review.

The exact-provider plans in [PR #102](https://github.com/mlznlv/proxmox-iac-toolkit/pull/102) used the locked v0.111.1 build at source revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`, refresh disabled, and synthetic prior states. The pinned update path sends no deletion for retired `ipconfigN`, and the read path restores them to state. Modeled later plans repeatedly propose removal; every initialization difference requests cloud-init rebuild and, by default, reboot of a running VM. This is provider planning plus source evidence, not executed apply/refresh or live guest evidence. Repeated apply is not a supported convergence remedy.

Implementation evidence must cover each supported transition, unchanged primary configuration and MAC, and subsequent no-op planning with source-grounded post-update state; module mocks alone cannot establish convergence or runtime MAC continuity. Declared MAC uniqueness is case-insensitive and includes a declared primary MAC when that input is implemented; undeclared or network-wide uniqueness is not guaranteed. Supported addressing changes retain reboot, new-instance, and possible SSH host-key regeneration consequences.

As for VLAN, a build merely allowed by the executable constraint acquires no lifecycle evidence until reviewed, and provider upgrades must re-evaluate the exact-build planning and update/read paths. Restoring retirement requires a later Architecture decision with evidence of retired-entry cleanup and convergent read-back for all excluded transitions, without VM recreation or competing ownership. No provider upgrade, new PVE target, or live-testing requirement is selected here.

### DHCP addressing

The accepted DHCP capability adds an explicit IPv4 DHCP mode for the primary attachment of `proxmox-linux-vm` on the same PVE 9.x target, provider line, and resource. It relies on Proxmox's cloud-init IP configuration accepting `dhcp` and rendering it as a DHCPv4 subnet for that interface.

Its lifecycle contract is that switching between static and DHCP preserves the VM. As for VLAN, that contract is backed by provider-level evidence for the exact locked build recorded before implementation is accepted, a build merely allowed by the version constraint does not acquire it until reviewed, and a provider that plans VM replacement for an addressing-mode change is blocked pending Architecture review. Preserving the VM does not preserve the guest's address or SSH host keys. The capability also adds the optional primary-attachment MAC address, which ADR 0011 gave only to additional attachments; changing it preserves the VM while replacing the device the guest sees.

### VM DNS search domain

[ADR 0017](decisions/0017-explicit-vm-dns-search-domain.md) adopts a required explicit consumer-owned single DNS search domain for the VM. This is an approved breaking input addition awaiting implementation, not an existing VM input or a new PVE/provider target. The VM name remains one DNS label; the combined generated `name.domain` must pass the locally decidable length limit, not just each input separately. DNS servers remain required, and primary IPv4 static/DHCP, optional static IPv6, additional attachments and declared `connection` metadata retain their contracts.

VM-specific source for locked v0.111.1 at `b22fe919fc34476b232191b69c8907f0c1aa5bea` and qemu-server at `14c0f871fa926e04eee090afae5d2d8670aa4a79` establishes independent template/node search-domain inheritance despite explicit nameservers, nonempty-domain request/read mapping and the absent empty-domain deletion path. The VM API accepts a string; neither that acceptance nor LXC's different schema establishes a safe VM no-search sentinel.

Supported explicit-domain adoption and nonempty-to-nonempty changes must preserve the VM and converge. Developer acceptance requires exact-provider implementation evidence and subsequent no-change plans grounded in update/read behavior, separately from module mocks. Removal and return to inheritance are unsupported. A build merely allowed by the provider constraint acquires no lifecycle evidence until reviewed; upgrades must re-evaluate this gate.

The [investigation record](https://github.com/mlznlv/proxmox-iac-toolkit/issues/121#issuecomment-6233199488) distinguishes pinned source inspection from extracted DNS/hostname-helper probes with a fictional resolver reader. These are not full installed Proxmox/cloud-init or guest tests. Initialization updates can rebuild cloud-init and reboot a running VM; generated FQDN and instance identity may change, with the established reconfiguration, possible host-key regeneration and connectivity consequences. None of this establishes actual guest DNS, hostname, reboot, SSH or reachability behavior. No provider upgrade, LXC DNS change or live-testing requirement is introduced.

### Static IPv6 addressing

The accepted IPv6 capability adds optional static IPv6 addressing to the primary attachment of `proxmox-linux-vm` on the same PVE 9.x target, provider line, and resource. Only static IPv6 is supported, because in cloud-init 25.1.4, the upstream version Debian 13 packages, the ENI, netplan, and systemd-networkd renderers render Proxmox's dynamic IPv6 forms differently while all rendering a static address and gateway.

Its lifecycle contract is that adding, changing, and removing IPv6 preserves the VM. As for VLAN, that contract is backed by provider-level evidence for the exact locked build recorded before implementation is accepted, a build merely allowed by the version constraint does not acquire it until reviewed, and a provider that plans VM replacement for an IPv6 change is blocked pending Architecture review.

### LXC capability

The first reusable LXC capability, `proxmox-linux-container`, targets the same PVE 9.x major and `bpg/proxmox` provider line as the VM module, through the `proxmox_virtual_environment_container` resource. It selects no other provider line or resource family.

Its lifecycle contract, reconciled in [ADR 0015](decisions/0015-first-lxc-lifecycle-and-dns-contract.md), is that network, DNS servers and search domain, name, memory, and CPU changes and root-filesystem growth preserve the container, while template, datastore, node, and identifier changes replace it. Network, DNS, name, and memory changes request a reboot of a running container; CPU and size-only growth do not on the pinned path. A bootstrap-key change preserves the container too, but only because the module declines to act on one: the provider would otherwise force replacement.

Root-filesystem shrinking is unsupported. The v0.111.1 planner at source revision `b22fe919fc34476b232191b69c8907f0c1aa5bea` can plan a shrink as an update rather than replacement, and its update path refuses it. Nesting is enabled by default with a consumer choice at creation only; later toggles are unsupported because the inspected update request adds non-nesting false flags and Proxmox restricts those changes to `root@pam`. That elevated identity is not a prerequisite this capability adopts. Current-input validation cannot enforce either history-dependent restriction; consumers must reject decreases and later toggles during plan review. A plan's update action is not evidence that either operation is supported.

Both DNS servers and a non-empty, valid single search domain are consumer-supplied requirements. The `dns_search_domain` input has no default and maps to `initialization.dns.domain`, preventing the independent node-domain fallback in the inspected Proxmox setup path. Empty or omitted provider domains restore fallback rather than disable search; a no-search mode remains deferred. The exact provider's create/update/read paths and schema support explicit domains, but that source evidence does not establish actual guest resolver behavior.

As for VLAN, supported lifecycle claims require provider-level evidence for the exact locked build recorded before implementation is accepted; a build merely allowed by the version constraint does not acquire it until reviewed, and a provider that plans replacement for a change the contract preserves is blocked pending Architecture review. The corrected restrictions use the implementation author's credential-free, refresh-disabled plans against synthetic states in [PR #107](https://github.com/mlznlv/proxmox-iac-toolkit/pull/107), plus independently inspected pinned provider, SDK, and Proxmox sources linked in ADR 0015. They are not executed apply/refresh, an observed authorization refusal, or live toolkit evidence. Provider upgrades must re-evaluate supported transitions and these limitations, not silently enable shrinking or later nesting toggles.

Further behaviours of the pinned build belong to this contract. Containers start again when their host boots, because the module declares start-on-boot rather than inheriting the provider's default. Reading a started container that has an interface waits up to ten seconds for it to report an address, warning rather than failing on timeout; that wait is the provider's, and no toolkit output depends on what it returns. Omitting a swap input uses the provider's zero-swap default; it is not a consumer-selected swap policy, and no override is introduced.

### Container template contract

When implemented, the `proxmox-linux-container` module will require a consumer-supplied Proxmox container template that:

- is a Debian root filesystem that Proxmox recognizes and configures through its Debian operating-system type;
- starts under an init system compatible with an unprivileged container and the nesting setting the consumer chooses; and
- contains an SSH server that accepts public-key login for the root account.

Debian Stable container templates are expected-compatible targets for this contract. They are not runtime-validated reference platforms, and no other distribution is targeted by this capability.

## Guest capability contract

The `qemu_guest_agent` role requires a managed guest with:

- a Python version supported by the repository's declared Ansible toolchain;
- APT package management;
- systemd service management;
- the `qemu-guest-agent` package and service available under that name;
- the guest-agent channel present in the VM, because the service is bound to that device on the targets below and cannot start without it; and
- SSH access through an identity able to perform the role's privileged operations non-interactively.

Debian Stable and Kali Rolling are expected-compatible targets for this capability contract. They are not runtime-validated reference platforms under the current evidence model. Other Debian-family distributions that meet the same capabilities may also work, but the toolkit makes no distribution-wide guarantee.

On those targets the guest-agent unit is device-activated: it is bound to the guest-agent channel, started from a udev rule when that device appears, and carries no installation configuration, so `systemctl is-enabled` reports `static`. The role's obligation there is that the package is installed and the service is running; enabling it for boot is not something a guest can configure, and the toolkit does not claim it.

The consumer-supplied source template must support the cloud-init bootstrap inputs used by the OpenTofu module: static IPv4 addressing, gateway, DNS servers, username, and SSH public keys. The template need not contain `qemu-guest-agent`: the module attaches the channel at creation and waits for no agent, so the package arrives afterwards with the Ansible role. A consumer that declares additional attachments also needs a template whose cloud-init applies network configuration to each addressed interface identified by MAC address; the toolkit does not claim that a particular template does. A consumer that selects DHCP needs a template whose cloud-init renders a DHCPv4 subnet into a running DHCP client, and a DHCP service and naming it controls. A consumer that declares IPv6 needs a template whose cloud-init renders a static IPv6 subnet and gateway, and IPv6 service it controls.

## Consumer revision and example compatibility

The initial coordinated consumer contract is revision-based: a consumer records one immutable full toolkit commit SHA in source control, establishes one checkout at that revision, and consumes both the OpenTofu module and Ansible role from it. This makes the selected source revision reproducible without choosing the consumer's acquisition mechanism or checkout location.

The coordinated workflow continues to use the immutable full commit SHA as its exact source revision. `v0.1.0-alpha.1` is the discoverable version identity, and its GitHub Release states the full SHA to which that immutable tag resolves. The tag does not replace the consumer's source-controlled SHA pin or change who owns checkout acquisition and updates.

Consumers upgrade deliberately. For a later release they review its changelog, compatibility snapshot, and any migration guidance before changing their source-controlled full-SHA declaration. The toolkit does not update consumer checkouts, state, inventories, provider constraints, or configuration automatically.

The approved M4 separate-repository example inherits the PVE target and guest capability contract on this page. It does not add a supported PVE version, provider line, guest distribution, or validated reference platform. Its public validation is structural and credential-free, so a passing example does not add live compatibility evidence.

## Current evidence level

The first slice requires public, credential-free static and contract validation for:

- module inputs, input validation, full-clone configuration, static addressing, the guest-agent channel attached at creation with provider IP waiting disabled, the default and overridden destroy policy, and the required `connection` output;
- Ansible syntax, lint, and the static package and service contract;
- connection-value composition without an OpenTofu-state dependency in the role; and
- repository validation and publication safety.

The approved VLAN expansion additionally requires credential-free module evidence for its default, accepted and rejected values, provider-field mapping, use of the existing single network device and module resource address, unchanged static-network and `connection` interfaces, and explicit exclusions. Module or mock-provider tests establish that module contract, not the provider's in-place lifecycle behavior; the separate provider-level evidence gate above establishes the no-replacement claim.

The approved multiple-attachment capability additionally requires credential-free module evidence that configurations without additional attachments are unchanged, and for slot order, per-attachment bridge, VLAN, address, and MAC mapping, the absent declared IP configuration of an addressless attachment, the primary-only gateway, the attachment limit and other local validation including case-insensitive declared-MAC uniqueness, the MAC output, the unchanged `connection` output and resource address, and exclusions. Its supported-update and convergence claims rest on the separate provider-level evidence gate above, not on mocks. An addressless declaration does not prove the absence of inherited template or guest configuration.
The approved LXC capability requires credential-free module evidence for its required inputs and validation, including the required search domain and provider-field mapping, template-based creation, Debian operating-system type, unprivileged mode, creation-time nesting default and override, the explicit start-on-boot declaration, single static network interface, password-free bootstrap keys, root-filesystem inputs, `connection` output, and exclusions. Its replacement, in-place, authorization, and no-node-domain-fallback claims rest on the separate provider-level evidence gate above, not on those tests. Completed implementation tests are a Developer acceptance gate, not a prerequisite for accepting the Architecture that authorizes them.

The approved DHCP capability additionally requires credential-free module evidence for the unchanged static default, the DHCP mapping without address or gateway, the connection-host rules and their validation in both modes, required DNS servers, the optional primary MAC address and its validation, the exclusion of DHCP from additional attachments, and the unchanged resource address. Its no-replacement claims rest on the separate provider-level evidence gate above.

The approved IPv6 capability additionally requires credential-free module evidence for its absence by default, the address and optional-gateway mapping alongside both IPv4 modes, rejected values including the non-address literals `auto`, `dhcp`, and `manual`, its exclusion from additional attachments, IPv4 and IPv6 DNS servers, the unchanged `connection` output, and the unchanged resource address. Its no-replacement claims rest on the separate provider-level evidence gate above.

This evidence does not demonstrate:

- live compatibility with a PVE 9.x installation or a particular `bpg/proxmox` release;
- successful plan, apply, clone, start, reconciliation, or destroy behavior, including graceful shutdown or reliable forced stop;
- successful cloud-init execution, SSH connectivity, or privilege escalation;
- Ansible convergence or idempotency on Debian Stable, Kali Rolling, or another real guest;
- that a guest agent starts once the channel is present, or that Proxmox subsequently reports one;
- that adding or removing the channel behaves as described on a running VM;
- successful VLAN application or update, suitable VLAN-aware bridge configuration, upstream switching or routing, guest reachability, uninterrupted SSH, or zero-downtime VLAN changes;
- successful network-device hot-plug or unplug, guest interface naming or configuration, cloud-init re-application or host-key regeneration on a given template, or reachability and routing through any additional attachment;
- lease acquisition, DHCP service, reservation, or name-registration behavior, a guest's DHCP client, or that a supplied connection host resolves to or reaches the guest;
- IPv6 configuration in a guest, a template's cloud-init renderer, IPv6 routing or router-advertisement behavior, reachability over IPv6, or the absence of guest-configured IPv6 addresses;
- successful container creation, template compatibility, in-container network, DNS, or key configuration, sufficiency of the nesting setting, container reboot, shutdown, forced stop, or destroy behavior;
- that a container starts after a host reboot, or that one reports an address within the bounded wait the provider's read path performs;
- a consumer's checkout-acquisition mechanism; or
- compatibility with a live consumer environment.

Static or mocked evidence must not be described as live infrastructure or guest compatibility evidence. A distribution becomes a validated reference platform only after public validation exercises it to the level claimed and this contract records that evidence.
