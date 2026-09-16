# ADR 0010: Adopt one unprivileged Debian container as the first reusable LXC capability

## Status

Accepted

## Context

M6 requires reusable LXC support alongside the Linux VM capability. A container is not a VM with a different resource name. On the supported `bpg/proxmox` provider build, `v0.111.1` at revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`, containers are a separate resource family whose lifecycle differs from the VM resource in ways that decide the public contract.

- **Bootstrap is performed by Proxmox, not cloud-init.** Proxmox writes the network configuration, hostname, DNS, and root's authorized keys into the container when it creates it. It does so only through a managed operating-system plugin: the `unmanaged` plugin implements every one of those steps as a no-op. The provider's default operating-system type is `unmanaged`.
- **Several inputs force replacement.** The provider marks the template file, the root-filesystem datastore, the unprivileged flag, and root's bootstrap keys and password as replacement-forcing, and forces replacement when the root filesystem shrinks.
- **Unprivileged is not the provider default.** Proxmox itself creates an unprivileged container unless asked otherwise and requires elevated host privilege for a privileged one, but the provider defaults `unprivileged` to `false`.
- **DNS has a host fallback.** When no nameserver is configured, Proxmox copies the node's own resolvers into the container.
- **Updates and destroy disrupt.** The provider reboots a running container after a network, DNS, or hostname change, and destroy shuts the container down with a forced stop when its timeout expires.
- **Reading a container waits briefly for an address.** When a started container has a network interface, the provider's read path asks Proxmox for its interfaces and waits up to ten seconds. Omitting the wait-for-IP block, or setting both of its options to false, selects waiting for any address rather than none. A timeout is logged as a warning, not returned as an error, so a guest that has not configured an address delays a read without failing it.
- **Containers start with their host unless told otherwise.** The provider defaults `start_on_boot` to true and sends it in the create request, so a module that says nothing about it still produces containers that start after a host reboot.
- **Systemd-based guests may need nesting.** Proxmox warns that a container running systemd newer than version 241 without the nesting feature may need it, and the provider defaults nesting to off.

These sources establish the basis for a public interface and an implementation evidence gate. They are source inspection, not live toolkit evidence.

This decision operates within the accepted [public toolkit and private deployment boundary](0001-public-toolkit-private-deployment-boundary.md), [lifecycle and orchestration ownership](0002-lifecycle-orchestration-ownership.md), and [local validation, Task, and CI security boundary](0004-local-validation-task-ci-security-boundary.md). It deliberately does not inherit the [Linux VM slice](0006-guest-agent-channel-at-creation.md) contract.

## Decision

Adopt one unprivileged Debian container, created from a consumer-supplied container template, as the first reusable LXC capability.

It is a new OpenTofu module at `tofu/modules/proxmox-linux-container/`, separate from `proxmox-linux-vm`, managing one `proxmox_virtual_environment_container` resource. It targets PVE 9.x through the existing `bpg/proxmox` provider line and shares no module code or public interface with the VM module.

The container is created from a template volume that already exists on Proxmox storage; the consumer acquires and maintains the template. The module declares the Debian operating-system type, always creates an unprivileged container, and enables nesting by default with a consumer override; it exposes no other container feature.

The consumer supplies the container name, which the module sets as the provider's `initialization.hostname` and which must therefore be a valid DNS name, and an optional identifier, node, template, root-filesystem datastore and size, CPU cores, and dedicated memory. A port value, defaulting to `22`, is published in `connection` as metadata and configures nothing, as the VM module's `ssh_port` does. The container has exactly one network interface on one consumer-selected bridge, with a required static IPv4 CIDR, gateway, and at least one DNS server. Root's SSH public keys are required creation-time bootstrap; no password is set.

OpenTofu owns the container resource, its network interface, and its root filesystem. The consumer owns the node, storage, bridge, addresses, sizing, identifiers, template, private keys, and all configuration inside the container after creation. Bootstrap keys give OpenTofu no continuing ownership of root's authorized keys, users, or SSH configuration.

The module exposes a required, non-sensitive `connection` output of `host`, `user`, and `port`: the declared IPv4 address without its prefix, `root`, and a port metadata value defaulting to `22`. It publishes no provider-reported container address, and `host` never depends on one. The provider's read path still waits up to ten seconds for a started container to report an address and warns on timeout; that bounded, non-fatal wait is the provider's, and the module neither configures nor consumes it.

The module declares start-on-boot explicitly rather than leaving the provider's default implicit, and declares it so that a container starts again when its host boots. That is the operational default this capability chooses, not an inherited one, and the module's own contract checks assert it. A consumer override and startup ordering remain deferred.

Network, DNS, and name changes and root-filesystem growth update the container in place, restarting a running container. Changing dedicated memory also updates in place and restarts it; changing CPU cores updates in place without a restart. Enabling or disabling nesting updates the configuration in place, but the provider requests no restart for it, so it takes effect only when the container next starts, and the module documents that rather than implying the change is live.

Template, datastore, node, and identifier changes and root-filesystem shrinking replace the container and are documented as destructive. A size decrease cannot be rejected before apply, because module validation cannot see the prior size; it reaches the consumer as a planned replacement, which plan review is the control for.

The pinned provider treats root's bootstrap keys as replacement-forcing, so leaving that behaviour exposed would make key rotation destroy the container. The module therefore ignores changes to the bootstrap key attribute on its own resource: a later key change produces no plan at all rather than a replacement, and rotating root's keys is guest configuration.

The module exposes no timeout or destroy-policy input. Destroy asks Proxmox to shut the container down with forcing already enabled and a timeout five seconds shorter than the provider's delete timeout, so under the defaults the guest gets 55 seconds before Proxmox stops it. Before implementation can be accepted, its pull request records provider-level evidence for these behaviors from the exact locked provider build, separately from module or mock-provider contract tests.

Normal public validation remains credential-free and does not claim successful container creation, template compatibility, in-container configuration, reachability, or reboot, shutdown, forced-stop, or destroy behavior. Exact inputs, examples, and validation implementation remain in their owning component and validation sources rather than this ADR.

## Consequences

- Consumers gain a container capability without changing the VM module, its interface, or its consumers.
- A consumer must supply a Debian container template with an SSH server that accepts root public-key login; template acquisition stays consumer-owned.
- Replacement-forcing changes destroy the container and its root filesystem. The module documents them, and plan review remains the consumer's control.
- Because the module ignores later changes to the bootstrap keys, editing them produces no plan, not even a no-op diff. A consumer who expects OpenTofu to rotate root's keys will see nothing happen, which is the intended bootstrap-only semantics but must be documented plainly.
- A network, DNS, name, or dedicated-memory change reboots a running container on the pinned provider, so an interruption is expected. A CPU-cores change does not.
- Nesting is on by default, which trades a broader container profile for systemd guests that behave as Proxmox expects. Changing it later is not live: the container keeps running with its previous profile until it is restarted.
- Destroy follows the provider's default timeouts, so a consumer who needs a longer graceful shutdown than 55 seconds has no input for it in this slice.
- Containers come back when their host reboots. That is a deliberate choice rather than an inherited default, and a consumer who wants a container to stay down after a host reboot has no input for it in this slice.
- Reading a started container can take up to ten seconds longer while the provider waits for it to report an address. The wait is bounded and non-fatal, and no toolkit output depends on its result.
- Module and mock-provider tests establish the public contract, but cannot alone establish the provider's in-place and replacement behavior.
- The `qemu_guest_agent` role does not apply to containers, and no container-specific Ansible role is introduced.

## Alternatives considered

- **Extend `proxmox-linux-vm` with a container mode:** rejected. The resource family, bootstrap mechanism, replacement semantics, and guest-agent assumptions differ, so a shared interface would couple two lifecycles and blur which contract applies.
- **Clone an existing container:** rejected for the first capability. It requires the consumer to maintain a source container, and the provider forces replacement on every clone input without establishing a benefit over creating from a template.
- **Inherit the provider's `unmanaged` operating-system type:** rejected. Proxmox would skip network, hostname, DNS, and key configuration, leaving a container the declared inputs do not describe.
- **Allow privileged containers:** rejected. A privileged container's root maps to host root, Proxmox requires elevated host privilege to create one, and no demonstrated need justifies the risk.
- **Support several distributions:** deferred. Each managed operating-system type configures the guest differently, and the demonstrated need is Debian.
- **Bootstrap with a password:** rejected. Key-based bootstrap is sufficient, and a password would be sensitive state the toolkit does not need.
- **Make DNS servers optional:** rejected. The Proxmox fallback would silently copy node-specific resolvers into a reusable component's result.
- **Include mount points, bind mounts, device passthrough, or ID mapping:** deferred. Each introduces storage or host-access ownership decisions beyond the smallest useful slice.
- **Leave `start_on_boot` unset:** rejected. The provider would still start every container with its host, so the operational default would be real but invisible, decided by a provider default rather than by this capability and absent from its contract checks.
- **Declare start-on-boot off:** rejected. A container that does not return after a host reboot is the more surprising default for the reusable capability this slice describes.
- **Expose start-on-boot as a consumer input now:** deferred. The demonstrated need is a container that comes back after a host reboot; an override belongs with startup ordering when something needs either.
- **Include VLAN tags, multiple interfaces, DHCP, or IPv6:** deferred. The VM decisions for those capabilities do not transfer, because Proxmox configures container networking itself rather than through cloud-init.

## Sources

- [`bpg/proxmox` v0.111.1 container `unmanaged` operating-system default](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L91)
- [`bpg/proxmox` v0.111.1 container bootstrap account replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L642-L676)
- [`bpg/proxmox` v0.111.1 container template replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L993-L1006)
- [`bpg/proxmox` v0.111.1 container hostname must be a valid DNS name](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L569-L575)
- [`bpg/proxmox` v0.111.1 container memory change requires a reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3867-L3886)
- [`bpg/proxmox` v0.111.1 container CPU change without a reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3603-L3633)
- [`bpg/proxmox` v0.111.1 container features change without a reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3728-L3735)
- [`bpg/proxmox` v0.111.1 container root-filesystem datastore replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L408-L414)
- [`bpg/proxmox` v0.111.1 container unprivileged default and replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L1152-L1158)
- [`bpg/proxmox` v0.111.1 container root-filesystem shrink replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L1182-L1228)
- [`bpg/proxmox` v0.111.1 container DNS, hostname, and network updates requiring reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3832-L4051)
- [`bpg/proxmox` v0.111.1 container reboot after update](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L4162-L4174)
- [`bpg/proxmox` v0.111.1 container destroy with forced stop](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L4204-L4236)
- [`bpg/proxmox` v0.111.1 container `start_on_boot` default](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L98)
- [`bpg/proxmox` v0.111.1 container `start_on_boot` schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L1072-L1078)
- [`bpg/proxmox` v0.111.1 container create request sends `start_on_boot`](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L2180-L2207)
- [`bpg/proxmox` v0.111.1 container read waits for network interfaces](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3477-L3509)
- [`bpg/proxmox` v0.111.1 omitted wait-for-IP block selects waiting for any address](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L4259-L4283)
- [`bpg/proxmox` v0.111.1 container network-interface wait behaviour](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/containers/containers.go#L174-L218)
- [Proxmox container create applies keys, network, hostname, and DNS through the setup plugin](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L718-L736)
- [Proxmox `unmanaged` setup plugin no-ops](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Unmanaged.pm#L19-L85)
- [Proxmox container DNS host fallback](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L33-L54)
- [Proxmox container systemd nesting warning](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L662-L679)
- [Proxmox unprivileged create default and privileged-create permission](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/API2/LXC.pm#L272-L273)
