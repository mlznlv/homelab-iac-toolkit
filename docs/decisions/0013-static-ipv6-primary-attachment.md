# ADR 0013: Adopt optional static IPv6 on the primary VM attachment

## Status

Accepted

## Context

M6 requires IPv6 for the Linux VM capability. The accepted networking model is already layered: [ADR 0011](0011-multiple-vm-network-attachments.md) makes the primary attachment the only gateway and `connection` source and defines what an addressing change does to a running VM, and [ADR 0012](0012-dhcp-primary-attachment-addressing.md) gives that attachment exactly one IPv4 mode and a consumer-supplied connection host for addresses the declaration cannot know.

The supported sources constrain which IPv6 modes can have one meaning.

- **Proxmox offers four IPv6 forms.** A cloud-init IP configuration accepts a static IPv6 address with prefix length, `auto` for stateless autoconfiguration, `dhcp`, or `manual`, which configures no address, and an IPv6 gateway only alongside an IPv6 address.
- **Proxmox renders them as distinct cloud-init subnets.** A static address becomes a `static6` subnet carrying the gateway, `auto` becomes `ipv6_slaac`, and `dhcp` becomes `dhcp6`. The pinned `bpg/proxmox` build, `v0.111.1` at revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`, passes the IPv6 address and gateway strings through without validating them.
- **Cloud-init does not give the dynamic forms one meaning.** In cloud-init 25.1.4, the upstream version Debian 13 packages, the ENI renderer turns `ipv6_slaac` into stateless autoconfiguration, the netplan renderer turns every dynamic IPv6 subnet type, `ipv6_slaac` included, into DHCPv6, and the systemd-networkd renderer enables DHCPv6 only for `dhcp6` and renders nothing for `ipv6_slaac`. All three render a static IPv6 address and its gateway.
- **DNS servers may be IPv6.** Proxmox's cloud-init nameserver setting accepts a list of IPv4 or IPv6 addresses.

These sources establish the basis for a public interface and an implementation evidence gate. They are source inspection, not live toolkit evidence.

This decision operates within the accepted [public toolkit and private deployment boundary](0001-public-toolkit-private-deployment-boundary.md), [lifecycle and orchestration ownership](0002-lifecycle-orchestration-ownership.md), [local validation, Task, and CI security boundary](0004-local-validation-task-ci-security-boundary.md), [established Linux VM slice](0006-guest-agent-channel-at-creation.md), [multiple-attachment contract](0011-multiple-vm-network-attachments.md), and [DHCP contract](0012-dhcp-primary-attachment-addressing.md).

## Decision

Adopt optional static IPv6 addressing, alongside the existing IPv4 mode, for the primary attachment of `proxmox-linux-vm`.

IPv6 is off by default, and a configuration that does not declare it plans exactly as before. When declared, it consists of a required IPv6 address with prefix length and an optional IPv6 gateway, which may be a global or link-local address. It is added to the primary attachment's existing cloud-init IP configuration and changes neither its IPv4 mode nor that mode's rules. The attachment remains dual-stack: an IPv4 mode, static or DHCP, stays required, and IPv6-only addressing is deferred.

Stateless autoconfiguration and DHCPv6 are not supported. The dynamic forms Proxmox offers do not produce the same guest configuration across cloud-init renderers, so the toolkit cannot give either a single meaning. The module rejects `auto`, `dhcp`, and `manual` before apply rather than forwarding them, because the pinned provider validates none of them. IPv6 on additional attachments is also deferred.

DNS server addresses may be IPv4 or IPv6, and at least one remains required.

The `connection` output is unchanged: the declared IPv6 address never becomes `host` automatically. A consumer that connects over IPv6 supplies the ADR 0012 connection host, which may be an IPv6 literal or a name.

OpenTofu owns the declared IPv6 address and gateway. The consumer owns prefix allocation, address uniqueness, routing, router advertisements, upstream IPv6 service, and consistency between the address, gateway, and the attachment's network. Ansible does not acquire guest-network ownership.

Adding, changing, or removing IPv6 must update the existing VM in place. Each is an addressing change under ADR 0011: it reboots a running VM on the pinned provider, and the next boot is a new cloud-init instance that re-applies network configuration and regenerates SSH host keys unless the template disables it. Before implementation can be accepted, its pull request records provider-level evidence for adding, changing, and removing IPv6 from the exact locked provider build, separately from module or mock-provider contract tests. A later supported provider that plans replacement for an IPv6 change is blocked pending Architecture review.

Normal public validation remains credential-free and does not claim IPv6 configuration in a guest, routing, router-advertisement behavior, reachability over IPv6, or the absence of other IPv6 addresses the guest may configure for itself. Exact inputs, examples, and validation implementation remain in their owning component and validation sources rather than this ADR.

## Consequences

- Existing consumers see no change unless they declare IPv6.
- A consumer gains deterministic dual-stack addressing that every renderer in the pinned cloud-init version renders the same way.
- A consumer whose network relies on stateless autoconfiguration or DHCPv6 for guests is not served by this decision and continues to configure IPv6 in the guest itself.
- Adding, changing, or removing IPv6 reboots a running VM and can regenerate its SSH host keys.
- Removing the declared IPv6 address does not claim to remove IPv6 from the guest: addresses the guest derives from router advertisements are outside the declaration.
- Module and mock-provider tests can establish the IPv6 input contract and mapping, but cannot alone establish the provider's in-place lifecycle behavior.

## Alternatives considered

- **Support stateless autoconfiguration through `auto`:** deferred. Cloud-init 25.1.4 renders it as autoconfiguration under ENI, as DHCPv6 under netplan, and as nothing specific under systemd-networkd, so its guest meaning depends on the template.
- **Support DHCPv6 through `dhcp`:** deferred. It shares that renderer dependence for the forms Proxmox generates, adds a consumer DHCPv6 service dependency, and has no demonstrated need.
- **Support IPv6-only addressing:** deferred. It would make the accepted IPv4 inputs optional and change the `connection` rules for every mode.
- **Derive `host` from the IPv6 address when declared:** rejected. It would silently change the published host for existing static consumers who add IPv6, and ADR 0012 already provides an explicit host.
- **Require an IPv6 gateway:** rejected. The consumer's network may supply the default route by router advertisement, and Proxmox treats the gateway as optional.
- **Allow IPv6 on additional attachments:** deferred. It would add per-attachment IPv6 route questions without a demonstrated need.

## Sources

- [Proxmox cloud-init IPv6 address and gateway format](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Network.pm#L170-L205)
- [Proxmox IPv6 configuration values](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L634-L644)
- [Proxmox cloud-init IPv6 subnet rendering](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L566-L578)
- [Proxmox cloud-init nameserver format](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer.pm#L825-L832)
- [Proxmox address format accepting IPv4, IPv6, or DNS names](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L755-L765)
- [Proxmox list formats validating each element](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L991-L1004)
- [`bpg/proxmox` v0.111.1 IPv6 IP configuration schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L927-L950)
- [`bpg/proxmox` v0.111.1 IP configuration encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/vms/custom_cloud_init.go#L80-L102)
- [cloud-init 25.1.4 dynamic IPv6 subnet types](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/net/__init__.py#L22-L27)
- [cloud-init 25.1.4 ENI IPv6 rendering](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/net/eni.py#L449-L470)
- [cloud-init 25.1.4 netplan IPv6 rendering](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/net/netplan.py#L108-L125)
- [cloud-init 25.1.4 systemd-networkd subnet rendering](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/net/networkd.py#L152-L186)
