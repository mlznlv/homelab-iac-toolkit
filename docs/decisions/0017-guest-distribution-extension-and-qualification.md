# ADR 0017: Qualify guest distributions separately for VM templates, LXC, and Ansible roles

## Status

Accepted

## Context

A guest distribution enters the toolkit in three places, through three different mechanisms with different owners. Support established in one says nothing about the others.

- **VM templates.** `proxmox-linux-vm` full-clones a consumer-supplied template and has no distribution input. Its template contract in [Compatibility](../compatibility.md#guest-capability-contract) is capability-based and names no distribution; the IPv6 renderer reasoning in [ADR 0013](0013-static-ipv6-primary-attachment.md) was made against cloud-init 25.1.4 as Debian 13 packages it. A clone copies its template's Proxmox configuration, and the module sets neither of the two cloud-init settings below, so the template or Proxmox's default decides them. For a Linux guest Proxmox generates NoCloud data unless that configuration selects another format. The user data makes the bootstrap account cloud-init's default user under the declared name, so its groups and sudo rules come from the template's cloud-init configuration, and it asks cloud-init to upgrade packages unless the configuration turns that off; cloud-init does so once per instance, so again after an addressing change starts a new one. The pinned provider marks the clone source as replacement-forcing, so a different template for an existing VM means replacing it.
- **LXC.** Proxmox, not cloud-init, configures a container through a setup plugin per operating-system type. On the pinned pve-container 6.1.14, unless the declared type is `unmanaged`, the plugin is chosen by detecting the distribution in the root filesystem: a declared type that differs from the detected one draws a warning rather than an error, and the detected type is written to the container's configuration at creation. Init, network, hostname, DNS, and timezone setup runs again on every container start, not only at creation. The Debian plugin refuses releases older than 4 and only warns for releases newer than 14. The pinned `bpg/proxmox` build accepts its own fixed list of types, which is not the list of plugins Proxmox has, and reads the stored type back. `proxmox-linux-container` fixes the Debian type under [ADR 0015](0015-first-lxc-lifecycle-and-dns-contract.md). The declared type therefore does not decide which setup a template receives, and a template that is not Debian is outside the module's contract whatever Proxmox detects.
- **Ansible roles.** The `qemu_guest_agent` role's contract is capability-based: a target Python the declared `ansible-core` supports, APT, systemd, the `qemu-guest-agent` package and service under that name, the guest-agent channel, and non-interactive privileged SSH. Its tasks call Ansible's generic package and systemd modules, but its contract is what it declares, not what those modules might run on. [ADR 0006](0006-guest-agent-channel-at-creation.md) showed that a distribution's packaging decides whether its unit can be enabled at all.

All current evidence is credential-free: mocked module tests and static role checks, exact-provider plans and source, and pinned upstream source and packaging. The expected-compatible targets in Compatibility rest on that evidence. Nothing has run against a Proxmox VE or a guest, and the isolated live-validation path in [#105](https://github.com/mlznlv/proxmox-iac-toolkit/issues/105) is not accepted. No consumer has demonstrated a need for another distribution; [#104](https://github.com/mlznlv/proxmox-iac-toolkit/issues/104) remains blocked on consumer evidence, and the M9 entry criteria are not met.

These sources establish the basis for a policy. They are source inspection, not live toolkit evidence.

This decision operates within [ADR 0001](0001-public-toolkit-private-deployment-boundary.md), [ADR 0002](0002-lifecycle-orchestration-ownership.md), [ADR 0004](0004-local-validation-task-ci-security-boundary.md), ADR 0006, and ADR 0015.

## Decision

Assess additional guest distributions separately for three tracks, under the evidence, lifecycle, and gate rules below. This decision selects no distribution, changes no component, and unblocks no Issue.

**Tracks and extension boundaries.** Support is never inferred from one track to another.

- **VM template track:** the template contract of `proxmox-linux-vm`. Three cases stay distinct. A template that meets the unchanged capability contract is a consumer-owned suitability judgement: it needs no decision and gains no toolkit claim. Naming a distribution release as a target is a compatibility claim and needs the qualification below. Anything that changes the module, such as a distribution-specific input, a cloud-init format or datasource choice, custom cloud-init data, or another bootstrap mechanism, is a new capability with its own Architecture decision and exact-provider evidence, not a compatibility claim.
- **LXC track:** the operating-system type of a container component. The Debian module has no extension point. Another distribution needs a target-specific decision covering its type, setup plugin, template contract, authorization, lifecycle, and placement; neither a different template nor exposing the fixed type as an input of the Debian module is a substitute for that decision.
- **Ansible track:** each role's declared guest contract, qualified per role and per release. A qualification for one role qualifies no other.

A VM or LXC qualification qualifies no role, and a role qualification qualifies neither guest type. The VM and LXC tracks do not qualify each other for the same distribution. The `qemu_guest_agent` role never applies to a container. Composing separately qualified components does not qualify the composition. Evidence may be reused across tracks as an input for the same exact identity, such as one inspection of a release's guest-agent packaging serving both the role and a VM paired with it, but each track states its own claim. An existing component is reused for a new target only within its unchanged contract, which the VM module's template contract allows and the Debian container module's fixed type does not.

**What a qualification establishes.**

- **VM:** the template's provenance; its cloud-init version, datasource, format, and active network renderer; that this cloud-init renders each module capability the claim covers as the contract assumes; the bootstrap account's privilege from the template's default-user configuration; what first boot changes, including the package upgrade; what a new cloud-init instance re-applies after an addressing change, including SSH host-key regeneration; and, when paired with a role, the guest-agent packaging. Template content does not change what the provider plans, so exact-provider evidence is needed only when the module or provider changes.
- **LXC:** the type and its pinned Proxmox setup plugin: what it writes for network, hostname, name servers, search domain, and root's keys, at creation and on every start; the release limits it applies; agreement between detection and the declared type; the template contract, including an init system that runs unprivileged under the chosen nesting value and an SSH server accepting root's public-key login; and exact-provider evidence for the create request, the type read back, and the lifecycle of template and type changes.
- **Ansible:** per role, the target Python, package manager and exact package name, service manager, unit name and activation semantics, non-interactive privilege escalation, inventory and connection assumptions, and device prerequisites such as the guest-agent channel. A runtime claim also requires convergence and a second run that reports no change.

**Privilege.** No qualification may adopt a privileged container, a container feature other than nesting, a `root@pam`-only operation, or interactive privilege escalation. Each of those needs its own decision.

**Evidence classes.** Four are kept distinct, and the first three are credential-free:

1. **Static and mocked:** what the toolkit declares, through module tests against a mocked provider and static role checks.
2. **Exact-provider:** schema, source, and credential-free plans for the exact locked provider build, with the Proxmox source on the path it drives.
3. **Pinned guest source:** distribution packaging, cloud-init, and Proxmox setup-plugin source at the versions the target ships or runs.
4. **Guest runtime:** observed execution against Proxmox VE and a guest.

**Claim levels.** A distribution release not named in Compatibility is not targeted: it may work where it meets a contract, and the toolkit claims nothing for it. An **expected-compatible** target requires the applicable classes 1 to 3 for the exact identity recorded, and must not be described as validated. A **runtime-validated reference platform** requires class 4 at the level claimed, collected through an accepted isolated live-validation path and recorded in Compatibility. Consumer-run results can show a need but are not toolkit runtime evidence. Normal public CI remains credential-free.

**Qualification record.** Each claim is recorded with sanitized, public values only: the track and component; the distribution, exact release, and architecture; the public template or image identity, with its checksum where one is published, and never a private storage path or volume; the versions acting on it, including the PVE major and the relevant Proxmox package, the provider build and source revision, and `ansible-core`, cloud-init, init system, and Python as applicable; the evidence class behind each claim; what was executed and what was only inspected; failures and counterexamples; and the toolkit commit evaluated. A release-series name such as Debian Stable does not carry a claim to a release that was not evaluated.

**New deployments and existing guests.**

- A VM or LXC qualification covers guests created from the qualified identity. An Ansible qualification covers a guest at the qualified release when the role runs; it does not qualify the upgrade that produced that release or package state an earlier release left behind.
- In-place updates keep their documented consequences. The target-specific ones, what a new cloud-init instance re-applies and what container setup rewrites on each start, must be recorded by the qualification.
- A distribution change of an existing guest is never an in-place transition. On the pinned provider, a VM's template change is a replacement that destroys the VM and its disks; a container's template change destroys it and its root filesystem; changing a container's declared type does not convert its distribution. The consumer-owned path is a new guest, consumer-owned data migration, and reviewed retirement of the old guest. The toolkit offers no in-place conversion, state rewriting, import, or automatic data migration.
- A release upgrade inside a guest is a consumer-owned guest operation that the toolkit neither performs nor detects. Qualifying a release for new guests does not qualify the upgrade path to it, and an upgraded guest is covered only where a decision qualifies that path. For containers, setup runs against the upgraded root filesystem at every start, so that path is evaluated against the pinned plugin.
- Bootstrap remains the minimum creation-time step ADR 0002 allows. A target whose bootstrap would write configuration an Ansible capability owns, or keep managing the guest after creation, needs an ownership decision rather than a qualification.

**Requalification.** Before Compatibility keeps a claim, the affected tracks are re-evaluated when the release changes or reaches end of life, including when a release-series name moves; a template or image rebuild changes cloud-init, the init system, package or unit names, or SSH defaults; the PVE major or the Proxmox package on the path changes; the provider build changes, as existing evidence gates already require; an `ansible-core` change alters target Python support or module behaviour; the component contract changes; or a credible counterexample is reported. Until then a claim covers only the identities recorded. Requalification that keeps the claim and contract is an Architecture-reviewed Compatibility update with its record. Narrowing or withdrawing a target also updates the changelog and migration notes, and existing guests are not converted.

**Documentation.** Adding, changing, or withdrawing a target updates the target-specific ADR, Architecture where a contract changes, Compatibility, the component README, consumer documentation where the workflow changes, and the changelog with concise migration actions. Migration notes describe the consumer-owned replacement path and its destructive consequences, never a conversion. Repository design changes only when a decision places new content.

**Placement.** No operating-system selector, distribution plugin layer, per-distribution hierarchy, or other abstraction is introduced. A target-specific decision states whether its content belongs in an existing component or a new one.

**Expansion trigger and gates.** Expansion starts only from a demonstrated consumer requirement for a specific distribution and release with a repeatable workload that current targets cannot meet. It is recorded, sanitized, in an Architecture change Issue: the operations and problems observed, why current targets cannot meet them, which tracks apply, and the privilege and maintenance constraints. A planned runner, a desired catalog, or a distribution's popularity is not a trigger. The gates are separate, and each must be met: the recorded need; the applicable milestone prerequisites; an Accepted target-specific Architecture decision; and a focused PO specification. This decision satisfies none of them.

**Unchanged.** The Debian LXC module's fixed type, defaults, public interface, and ADR 0015 lifecycle, DNS, and bootstrap restrictions; the VM and role contracts; and the existing expected-compatible targets keep their wording and evidence. They are brought into the record format at their next requalification trigger.

## Consequences

- Architecture can assess a requested distribution track by track, and PO can scope qualification or implementation from a checklist rather than invent policy.
- A consumer may use any VM template that meets the contract, at their own judgement, without the toolkit claiming that template.
- Another container distribution remains a component decision. Choosing a different template under the Debian module is outside its contract.
- No compatibility claim can exceed its evidence class, and no target reaches runtime-validated before an isolated live path is accepted.
- Consumers changing distribution replace guests and own their data migration; nothing in the toolkit makes that transition safe or automatic.
- Moving release names and rebuilt images create requalification work rather than silently extended claims.
- No component, interface, test, workflow, live infrastructure, or repository structure changes, and normal public validation remains credential-free.

## Alternatives considered

- **Infer support across tracks for a distribution that works on one:** rejected. The tracks use different bootstrap mechanisms, owners, and evidence.
- **Enable container distributions by template choice, or expose the type as an input now:** rejected. Proxmox selects the setup plugin by detection, so the declared type neither enables nor guards a distribution, and no target has been decided.
- **Introduce a generic operating-system selector or distribution matrix:** rejected. No demonstrated need justifies the abstraction.
- **Name targets from popularity or a planned runner:** rejected. Without a demonstrated workload there is nothing to qualify against.
- **Treat expected-compatible or consumer-run results as runtime validation:** rejected. Normal validation is credential-free, and toolkit runtime evidence needs an accepted isolated path.
- **Support in-place distribution conversion or automatic migration:** rejected. Template changes replace guests, type changes do not convert them, and guest data is consumer-owned.
- **Leave policy to each future target decision:** rejected. Each decision would invent its own evidence and lifecycle rules.

## Sources

- [Proxmox container setup plugins by type](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup.pm#L25-L38)
- [Proxmox container setup detecting the distribution and warning on a different declared type](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup.pm#L100-L127)
- [Proxmox Debian setup plugin release limits](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Debian.pm#L16-L59)
- [Proxmox container create detecting the distribution before writing the configuration](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/API2/LXC.pm#L594-L598)
- [Proxmox container setup on every start](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/lxc-pve-prestart-hook#L183-L184), [re-applying init, network, hostname, DNS, and timezone](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L698-L710)
- [`bpg/proxmox` v0.111.1 accepted container types](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/validators.go#L45-L59)
- [`bpg/proxmox` v0.111.1 container type read-back](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3334-L3363)
- [`bpg/proxmox` v0.111.1 container type update and reboot request](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L4062-L4080)
- [`bpg/proxmox` v0.111.1 replacement-forcing VM clone source](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L622-L628)
- [Proxmox VM clone copying the template's configuration](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/API2/Qemu.pm#L4510-L4579)
- [Proxmox VM cloud-init format default](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L94-L110)
- [Proxmox VM cloud-init user data, default user, and package upgrade](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L145-L189)
- [cloud-init 25.1.4 merging the declared user into the distribution's default user](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/distros/ug_util.py#L165-L238)
- [cloud-init 25.1.4 package upgrade once per instance](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/config/cc_package_update_upgrade_install.py#L24-L27)
