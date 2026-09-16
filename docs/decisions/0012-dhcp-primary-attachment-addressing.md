# ADR 0012: Adopt consumer-owned DHCP addressing for the primary VM attachment

## Status

Accepted

## Context

M6 requires DHCP-based addressing for the Linux VM capability. The first slice deliberately used declared static IPv4 addressing, and [ADR 0006](0006-guest-agent-channel-at-creation.md) made the module wait for no agent-reported address and publish none. [ADR 0011](0011-multiple-vm-network-attachments.md) then fixed the primary attachment as the only gateway and `connection` source, bounded addressing to positional cloud-init configurations, and defined what any addressing change does to a running VM.

The supported sources constrain what DHCP can mean.

- **Proxmox supports DHCP per interface.** A cloud-init IP configuration accepts the literal `dhcp` for IPv4, alongside `manual`, which this decision does not expose, and Proxmox documents that no explicit gateway should accompany DHCP. Proxmox renders it into cloud-init network data as a `dhcp4` subnet for that interface.
- **The provider passes the mode through.** The pinned `bpg/proxmox` build, `v0.111.1` at revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`, sends the IPv4 address string as given and omits an empty gateway.
- **DNS has a host fallback.** When no nameserver is configured, Proxmox writes the node's own resolvers into the cloud-init network data.
- **A DHCP address is unknown to the declaration.** The module derives `connection.host` from the declared static address. With DHCP there is none. The only address the provider can read back is one the guest agent reports, and the agent is installed after creation by the Ansible capability over SSH, which needs an address first.

These sources establish the basis for a public interface and an implementation evidence gate. They are source inspection, not live toolkit evidence.

This decision operates within the accepted [public toolkit and private deployment boundary](0001-public-toolkit-private-deployment-boundary.md), [lifecycle and orchestration ownership](0002-lifecycle-orchestration-ownership.md), [local validation, Task, and CI security boundary](0004-local-validation-task-ci-security-boundary.md), [established Linux VM slice](0006-guest-agent-channel-at-creation.md), [single-NIC VLAN contract](0009-first-m6-vlan-expansion.md), and [multiple-attachment contract](0011-multiple-vm-network-attachments.md).

## Decision

Adopt DHCP as an explicit, consumer-selected IPv4 addressing mode for the primary attachment of `proxmox-linux-vm`.

The primary attachment has exactly one IPv4 addressing mode. Static remains the default and keeps its existing contract: a required address in CIDR notation and a required gateway. DHCP is selected explicitly and forbids a declared address and gateway. A configuration that does not select DHCP plans exactly as before. DHCP on additional attachments remains deferred, because a DHCP server may supply a default route on each, which would reintroduce the multiple-default-route problem ADR 0011 avoided.

DNS servers remain required in both modes, so that Proxmox never substitutes the node's resolvers.

The required `connection` output keeps its `host`, `user`, and `port` shape. This refines [ADR 0011](0011-multiple-vm-network-attachments.md), which recorded that the output derives only from the primary attachment: how `host` is obtained changes here, while the rest of that decision, including the primary attachment as the sole source, stands. The module accepts an optional consumer-supplied connection host, a hostname or IP address literal. When supplied, it is published as `host` in either mode. In static mode without it, `host` remains the declared address. In DHCP mode it is required, and a DHCP configuration without it fails before apply. The module never derives `host` from a lease, an agent-reported or provider-read address, OpenTofu state, or generated inventory, and it never waits for an address.

OpenTofu owns the declaration that the primary attachment uses DHCP, and its MAC address where one is declared. The consumer owns the DHCP service, scopes, reservations, leases, name registration, and the guarantee that the supplied connection host reaches the guest. Ansible does not acquire guest-network ownership.

This decision introduces the optional primary-attachment MAC address input. [ADR 0011](0011-multiple-vm-network-attachments.md) gave an optional MAC address to additional attachments while preserving the primary attachment's existing inputs, so the primary has none today; the capability that needs one defines it rather than assuming that decision did. It is optional in both addressing modes, takes the same form and validation as an additional attachment's MAC address, and maps to the network device at slot `net0`. A reservation that must apply from the first boot requires it. Without it Proxmox assigns a MAC address at creation and the module publishes it afterwards, as it already publishes every attachment's. Changing it updates the VM in place, and on a running VM Proxmox unplugs the device and plugs a new one, so the guest sees a new interface and a reservation keyed to the old address stops matching.

Cloud-init configures DHCP on the primary interface at first boot, and bootstrap is otherwise unchanged. Apply completes without any evidence of a lease or of reachability; the connection host is declared metadata.

Switching between static and DHCP must update the existing VM in place. It is an addressing change under ADR 0011: it reboots a running VM on the pinned provider, and the next boot is a new cloud-init instance that re-applies network configuration and regenerates SSH host keys unless the template disables it. The guest's address may change, and the consumer updates anything that depends on it. Changing only the connection host changes no infrastructure. Before implementation can be accepted, its pull request records provider-level evidence for both transitions from the exact locked provider build, separately from module or mock-provider contract tests, and for the primary MAC address input: that a declared value reaches the primary device, and that changing it updates the VM in place rather than replacing it. A later supported provider that plans replacement for an addressing-mode change is blocked pending Architecture review.

Normal public validation remains credential-free and does not claim lease acquisition, DHCP service or reservation behavior, name registration, a guest's DHCP client, or reachability. Exact inputs, examples, and validation implementation remain in their owning component and validation sources rather than this ADR.

## Consequences

- Existing static consumers see no change, and may adopt the connection host to publish a name instead of an address.
- A DHCP consumer must supply a connection host its own infrastructure keeps accurate; the toolkit cannot tell whether it does.
- A consumer that wants a stable DHCP address from first boot declares the MAC address and creates the reservation before apply.
- The primary attachment gains an optional MAC address input here rather than in ADR 0011, so the implementation specification for this decision carries its mapping, validation, and lifecycle. A consumer that declares none sees no change.
- Changing the primary MAC address replaces the device the guest sees and stops a reservation keyed to the old address from matching, so it is a deliberate change rather than a cosmetic one.
- Switching modes reboots a running VM and can change its address and SSH host keys.
- The toolkit still reads no agent, lease, or state to learn an address, so apply and refresh never block on guest networking.
- Module and mock-provider tests can establish the mode contract and connection rules, but cannot alone establish the provider's in-place lifecycle behavior.

## Alternatives considered

- **Discover the address from the guest agent:** rejected. It reverses ADR 0006, blocks apply and refresh on an agent that the Ansible capability installs only after SSH already works, and makes `connection` depend on runtime state.
- **Publish a null or unknown `host` in DHCP mode:** rejected. `connection` is a required composition contract, and a silently missing host would move the failure to the consumer's inventory.
- **Read addresses from state or generate inventory:** rejected. Both cross the lifecycle and example boundaries the toolkit has already accepted.
- **Make DHCP the default:** rejected. It would change every existing consumer's addressing.
- **Make DNS servers optional in DHCP mode:** rejected. Proxmox would substitute the node's resolvers, an environment-specific default.
- **Allow DHCP on every attachment:** deferred. Several DHCP-supplied default routes need guest routing policy the toolkit does not own.
- **Integrate Proxmox SDN DHCP or IPAM:** rejected. It would make the toolkit manage network services outside the VM resource.

## Sources

- [Proxmox cloud-init IP configuration format and DHCP gateway guidance](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Network.pm#L153-L205)
- [Proxmox IPv4 configuration values](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L622-L632)
- [Proxmox cloud-init `dhcp4` rendering](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L552-L565)
- [Proxmox cloud-init DNS host fallback](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L127-L143)
- [`bpg/proxmox` v0.111.1 cloud-init IP configuration mapping](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L3616-L3658)
- [`bpg/proxmox` v0.111.1 IP configuration encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/vms/custom_cloud_init.go#L80-L102)
- [`bpg/proxmox` v0.111.1 agent-reported addresses](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/network/network.go#L184-L258)
- [`bpg/proxmox` v0.111.1 network-device MAC address schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/network/schema.go#L108-L114)
- [Proxmox MAC address assignment](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Network.pm#L216-L219)
- [Proxmox device unplug on MAC address or model change](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer.pm#L5114-L5130)
