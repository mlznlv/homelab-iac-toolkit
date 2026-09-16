# ADR 0011: Adopt ordered additional network attachments on the Linux VM capability

## Status

Accepted

## Context

M6 requires multiple network interfaces for the Linux VM capability. [ADR 0009](0009-first-m6-vlan-expansion.md) gave the existing single attachment an optional access VLAN and deferred more than one attachment. The supported `bpg/proxmox` provider build, `v0.111.1` at revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`, and Proxmox VE constrain what a second attachment can mean.

- **Identity is positional.** The provider models network devices as an ordered list whose position is the Proxmox slot `net0` to `net31`, reads them back by slot, and on update deletes any existing slot absent from the planned list. Cloud-init addressing is a separate ordered list mapped to `ipconfig0`, `ipconfig1`, and so on, emitted only for entries that declare something, with no deletion for entries that disappear.
- **Addressing is limited to eight.** The provider accepts at most eight cloud-init IP configurations, although it accepts up to thirty-two devices.
- **The guest identifies an interface by MAC address.** Proxmox assigns a random MAC address to a device that declares none. Its generated cloud-init network data describes only interfaces that have an IP configuration, matches each by MAC address, and names it `eth` followed by the slot index. Changing a device's MAC address or model makes Proxmox hot-unplug the device.
- **Addressing changes create a new cloud-init instance.** Proxmox derives the cloud-init instance identifier from a SHA-1 digest of the generated user and network data. The provider rebuilds the cloud-init drive after an initialization change and, with its default `reboot_after_update`, reboots a running VM. Cloud-init 25.1.4, the upstream version Debian 13 packages, applies network configuration by default only for a new instance, and its SSH module runs once per instance and deletes existing host keys unless configured not to.
- **Device changes otherwise hot-plug.** The provider applies a network-device change without requiring a reboot.

These sources establish the basis for a public interface and an implementation evidence gate. They are source inspection, not live toolkit evidence.

This decision operates within the accepted [public toolkit and private deployment boundary](0001-public-toolkit-private-deployment-boundary.md), [lifecycle and orchestration ownership](0002-lifecycle-orchestration-ownership.md), [local validation, Task, and CI security boundary](0004-local-validation-task-ci-security-boundary.md), [established Linux VM slice](0006-guest-agent-channel-at-creation.md), and [single-NIC VLAN contract](0009-first-m6-vlan-expansion.md).

## Decision

Adopt optional, consumer-ordered additional network attachments on the existing `proxmox-linux-vm` capability, on its existing `proxmox_virtual_environment_vm` resource and module resource address.

The existing attachment is the primary attachment. Its bridge, optional VLAN, static IPv4 address, gateway, and the global DNS servers keep their accepted contracts, and it is always slot `net0` and IP configuration `0`. A configuration declaring no additional attachment plans exactly as before.

Additional attachments default to none. The consumer declares them in an explicit order, and an attachment's identity is its position: the first additional attachment is slot `net1` and IP configuration `1`, and so on. The public interface must not derive that order implicitly. At most eight attachments are supported, the primary included.

Each additional attachment requires a bridge and accepts an optional access VLAN under ADR 0009's contract, an optional static IPv4 address in CIDR notation without a gateway, and an optional MAC address. Only the primary attachment carries a gateway. An attachment declared without an address is given no cloud-init IP configuration of its own, and the network data Proxmox generates describes only the interfaces that have one. That is what the module declares for a slot, not a guarantee about what the slot already contains: a retired configuration persists, as the retained-configuration rule below sets out. When no MAC address is declared, Proxmox assigns one. The module publishes every attachment's MAC address, in slot order, as a non-sensitive output. Locally decidable invalid values fail before apply.

OpenTofu owns every attachment, its tag, declared MAC address, and declared static address. Consumers own bridge and VLAN selection, bridge configuration, switching, routing, address allocation, and consistency between an attachment's network and address. Ansible does not acquire guest-network ownership. The `connection` output is unchanged and derives only from the primary attachment.

No attachment change may replace the VM. Adding an attachment after the last, removing the last additional attachment, and changing an attachment's bridge, VLAN, address, or MAC address update the VM in place. Removing or reordering a non-final attachment also updates in place but re-maps every later slot to the next attachment's settings; the module documents that disruption and cannot detect it before apply. Before implementation can be accepted, its pull request records provider-level evidence for these transitions from the exact locked provider build, separately from module or mock-provider contract tests. A later supported provider that plans replacement for an attachment change is blocked pending Architecture review.

Any addressing change is documented as rebooting a running VM on the pinned provider and making its next boot a new cloud-init instance.

A slot's cloud-init IP configuration is not cleared by removing an attachment or by making it addressless. The pinned provider omits an empty configuration from its update request and deletes none, and Proxmox's generator emits configuration for every slot that still has one, matched to the MAC address the slot's current device carries. The addressless guarantee therefore holds only for a slot that has never been addressed. Removing or de-addressing an attachment is supported and leaves its retired configuration in Proxmox; reusing that slot for an addressless attachment is not a supported way to reach an unconfigured interface, because the retired address can reach the new device. Clearing a retired configuration is a consumer action outside this capability. Implementation records the provider-level evidence that the update omits and does not delete the configuration, and the module documents the boundary rather than implying that removal clears anything.

DHCP, IPv6, gateways or routes on additional attachments, trunks, device models, firewall, MTU, rate, queue, and link-state settings, bridge management, network orchestration, and guest-network configuration remain deferred. Separate DHCP and IPv6 decisions must consume this decision's slot identity, primary-attachment connection source, eight-configuration limit, and addressing-change lifecycle rather than redefine them.

Normal public validation remains credential-free and does not claim device hot-plug, guest interface naming or configuration, cloud-init re-application, host-key regeneration, reachability, or routing. Exact inputs, examples, and validation implementation remain in their owning component and validation sources rather than this ADR.

## Consequences

- Existing consumers see no change unless they declare additional attachments.
- Slot position is a public identity. Removing or reordering a non-final attachment changes the identity or network of every later interface without replacing the VM, so consumers who need later interfaces to stay stable remove attachments from the end.
- A declared MAC address travels with its declaration. Whether a Proxmox-assigned MAC address stays with its slot or changes when a slot is re-mapped is not established by source inspection, so the implementation evidence records it for each transition and the module documents the result.
- Removing an address from a slot does not remove it from Proxmox. The retired configuration stays in the VM configuration and can be applied to whatever device later occupies that slot, so a consumer who retires an address and reuses the slot plans for that rather than expecting a clean one.
- An addressing change on any attachment, including the primary attachment's existing static address, reboots a running VM on the pinned provider and can regenerate its SSH host keys, so consumers should expect host-key verification to change.
- A guest with several default routes is avoided by construction, and routing policy stays guest configuration.
- Module and mock-provider tests can establish slot mapping and input structure, but cannot alone establish the provider's in-place lifecycle behavior.

## Alternatives considered

- **Identify attachments by consumer-chosen keys:** rejected. The provider can express only contiguous positional lists, so a key cannot keep its slot when another attachment is removed, and ordering keys implicitly would re-map slots whenever a key is inserted.
- **Treat every device as equal, without a primary attachment:** rejected. It would change the accepted single-attachment inputs, their defaults, and the `connection` derivation for every existing consumer.
- **Allow a gateway on every attachment:** rejected. Several default routes require guest routing policy the toolkit does not own.
- **Support up to thirty-two attachments:** rejected. Slots beyond the eighth could not carry cloud-init addressing under the pinned provider, giving attachments inconsistent capabilities by position.
- **Reject non-final removal:** not possible locally. Input validation cannot see the prior configuration, so the capability documents the re-mapping and relies on plan review.
- **Disconnect a retired attachment instead of removing it:** deferred. It keeps later slots stable but leaves inert devices, and no demonstrated need justifies exposing link-state settings.
- **Allow VM replacement for attachment changes:** rejected. A network change must not silently become destructive VM recreation.

## Sources

- [`bpg/proxmox` v0.111.1 positional network-device schema and limits](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/network/schema.go#L75-L162)
- [`bpg/proxmox` v0.111.1 network devices read back by slot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/network/network.go#L108-L182)
- [`bpg/proxmox` v0.111.1 network-device update and removal](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6821-L6847)
- [`bpg/proxmox` v0.111.1 eight cloud-init IP configurations](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L892-L957)
- [`bpg/proxmox` v0.111.1 positional IP configuration encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/vms/custom_cloud_init.go#L80-L102)
- [`bpg/proxmox` v0.111.1 initialization change requires cloud-init rebuild and reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6592-L6684)
- [`bpg/proxmox` v0.111.1 `reboot_after_update` default](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L48)
- [`bpg/proxmox` v0.111.1 cloud-init drive rebuild after update](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L7008-L7012)
- [Proxmox MAC address assignment](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Network.pm#L216-L219)
- [Proxmox device unplug on MAC address or model change](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer.pm#L5114-L5130)
- [Proxmox cloud-init network data by slot and MAC address](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L527-L579)
- [Proxmox cloud-init instance identifier digest](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L603-L608)
- [cloud-init 25.1.4 new-instance detection](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/stages.py#L535-L546)
- [cloud-init 25.1.4 network configuration applied only for a new instance by default](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/stages.py#L1078-L1090)
- [cloud-init 25.1.4 default network update events](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/sources/__init__.py#L277-L282)
- [cloud-init 25.1.4 SSH module frequency](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/config/cc_ssh.py#L32)
- [cloud-init 25.1.4 SSH host-key deletion default](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/config/cc_ssh.py#L99-L106)
- [Debian 13 cloud-init package version](https://sources.debian.org/src/cloud-init/25.1.4-1+deb13u1/)
