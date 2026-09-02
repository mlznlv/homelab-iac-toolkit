# ADR 0006: Adopt the coordinated first slice with the guest-agent channel present from creation

## Status

Accepted. Supersedes [ADR 0005](0005-first-reusable-toolkit-slice.md).

## Context

ADR 0005 selected a coordinated OpenTofu VM capability and Ansible guest-agent capability as the first reusable slice. That selection was right and is kept. The bootstrap order it recorded is not achievable on the platform its own compatibility contract names, and the decision text of an accepted ADR is immutable, so the correction is recorded here.

ADR 0005 treated one provider setting as a single decision when it governs two separable things: whether Proxmox attaches the guest-agent virtio channel to the VM, and whether the provider waits for the agent to report an address. It disabled both, and then asked Ansible to make the guest-agent service enabled and running before a later OpenTofu reconciliation turned the setting on.

Proxmox attaches the `org.qemu.guest_agent.0` channel only when the agent setting is enabled. Debian's `qemu-guest-agent.service` is bound to that device with `BindsTo=`, is started from a udev rule when the device appears, and carries an empty `[Install]` section. On a guest created the way ADR 0005 describes, the service therefore cannot be started, and cannot meaningfully be enabled either: `systemctl is-enabled` reports `static`, which Ansible's systemd module treats as already enabled, so the role would report success while changing nothing. The order is circular, and one half of it fails silently.

The escape ADR 0005 implied — enable the setting in a later apply — also costs more than it recorded. Proxmox does not hot-plug an agent change, so the VM must be stopped and started before the channel appears.

The pinned provider separates the two concerns: `agent.enabled` governs the channel, and `agent.wait_for_ip.disabled` governs whether the provider waits for agent-reported addressing during apply and refresh. That separation is what makes a non-circular order available without changing the slice's scope.

## Decision

Keep the coordinated OpenTofu VM capability and Ansible guest-agent capability as the first reusable toolkit slice, with the guest-agent channel present from creation.

**Channel exposure.** The OpenTofu component attaches the guest-agent channel when it creates the VM. The component's guest-agent input defaults to enabled, so the channel exists before any guest configuration runs, and the Ansible component can install and start the guest agent on its first run without a second apply and without a power cycle.

**Provider waiting.** The component never waits for agent-reported addressing. Waiting is disabled unconditionally rather than exposed as an input, so apply and refresh do not block on an agent that is not yet installed or running. Addressing remains the consumer's declared static IPv4 configuration, and the module publishes no agent-reported address attribute. This is what makes an exposed channel safe before the guest agent exists, and it is the reason ADR 0005's argument for disabling the channel no longer applies.

**Opting out.** A consumer may set the guest-agent input to `false`, which leaves the channel absent. The guest agent cannot run in that VM, so the Ansible component cannot bring its service up, and adding the channel later requires stopping and starting the VM. That combination is supported and must be documented as what it is: a VM without a guest agent, not a first step toward one.

**Guest service activation.** The Ansible component installs the `qemu-guest-agent` package and ensures its service is running. Whether the service can also be enabled for boot belongs to the target's packaging: where the unit is device-activated and static, as Debian's is, activation comes from udev when the channel appears, and no configuration in the guest can change that. The durable obligation is therefore that the package is installed and the service is running when the channel is present; enabling at boot is honoured where the packaging supports it and is not claimed where it does not.

The rest of ADR 0005's decision is carried forward unchanged:

- The OpenTofu component manages one full-clone Proxmox Linux VM from a consumer-supplied cloud-init template using `bpg/proxmox`, with declared static addressing and bootstrap access values, and does not configure the provider or a backend for the consumer.
- The component exposes a `stop_on_destroy` input that defaults to `true`, stopping the VM rather than requesting a graceful shutdown before destroy. A forced stop can interrupt workloads and lose unwritten data. Consumers may set it to `false` only when they accept reliance on a shutdown through ACPI or a running guest agent, and the risk of a blocked or timed-out destroy.
- The Ansible component consumes ordinary inventory and has no dependency on OpenTofu state or output schema.
- OpenTofu bootstrap inputs do not transfer continuing ownership of guest users or SSH configuration. OpenTofu owns the PVE VM lifecycle, Ansible owns guest-agent package and service state, and the consumer owns provider and backend configuration, credentials, templates, topology, sizing, inventory, private keys, and orchestration.
- The OpenTofu component exposes a required, non-sensitive `connection` output containing `host`, `user`, and `port`, derived from the declared address, the bootstrap username, and an `ssh_port` input defaulting to `22`. The port input is composition metadata and does not configure guest SSH. The descriptor does not create a required OpenTofu-to-Ansible integration, and Task does not wire the components together.
- Compatibility is explicit rather than floating: the public compatibility contract declares one supported PVE major and a capability-based guest contract. Adopting another PVE major requires compatibility review and validation, and a new ADR only if the durable policy or another architectural decision changes.
- Public evidence for this slice is credential-free static and contract validation, and must not be represented as live PVE, destroy, shutdown, cloud-init, SSH, distribution-convergence, or guest-agent integration evidence.
- Input and output names, exact provider and tool versions, executable provider constraints, and the particular test mechanism are implementation or compatibility declarations. They may change without superseding this ADR when the decision and public contract remain intact.

Credential-free validation cannot demonstrate a runtime sequence. Where a decision here depends on how a hypervisor or a distribution behaves, the reasoning is recorded against the upstream sources in Context, and remains a documented expectation rather than an evidenced result.

## Consequences

- The composed flow is one apply, then guest configuration: create the VM with the channel present and no agent waiting, compose inventory, run the role. No later reconciliation is required to make the guest agent work.
- A VM is created with a channel that has nothing listening on it until the role runs. The channel is inert until then, and the provider does not wait for it.
- Proxmox reports the guest as agent-enabled before an agent is running, so an operation that asks the agent for something — a filesystem freeze during backup, an agent-reported address in the UI — will report the agent as unavailable until the role has run. This is visible rather than hidden, and is the cost of removing the circular order.
- The module publishes no agent-reported addressing, and disabling the provider's IP waiting leaves those provider attributes empty. Consumers who want agent-reported addressing are outside this slice.
- Turning the channel off is a supported choice that produces a VM without a guest agent, and reversing it costs a stop and start.
- ADR 0005's requirement that the consumer guarantee a running agent before enabling the setting is withdrawn, because the provider no longer waits for one.
- The Ansible component's public contract is stated in terms its targets' packaging can satisfy, so the slice no longer claims an outcome that Debian's packaging makes impossible.

## Alternatives considered

- **Keep the channel absent and reduce the role to package installation:** rejected. It preserves ADR 0005's two-phase story at the cost of a VM stop and start that the decision never recorded, and it leaves the Ansible capability unable to assert that anything is running — a weaker contract than the slice was approved to deliver.
- **Attach the channel unconditionally, with no input:** rejected, though it is the smallest surface. A consumer who does not want a guest-agent channel should be able to say so, and the cost of keeping the input is one documented combination rather than a hidden failure.
- **Expose provider IP waiting as an input:** rejected. Waiting for an agent-reported address reintroduces the dependency this ADR removes, and no consumer need for it has been demonstrated. Static addressing is the slice's contract.
- **Install the guest agent from cloud-init instead:** rejected again, for ADR 0005's reason: it would put continuing package and service ownership inside infrastructure creation and would not exercise the Ansible lifecycle boundary.
