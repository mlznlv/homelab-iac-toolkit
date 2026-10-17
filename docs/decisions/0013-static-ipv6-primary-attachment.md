# ADR 0013: Adopt optional static IPv6 on the primary VM attachment

Status: Accepted.

## Decision

- Add optional static IPv6 to the primary attachment beside either required IPv4 mode, absent by
  default; accept an optional global/link-local gateway with an address.
- Reject `auto`, `dhcp` and `manual`; defer IPv6-only and additional-attachment IPv6.
- Permit IPv4/IPv6 DNS servers while keeping at least one required.
- Keep `connection` unchanged: IPv6 is used for access only through an explicit consumer host,
  not automatically when an IPv6 address is added.
- Require in-place add/change/remove with exact-provider lifecycle evidence; keep routing,
  prefix/uniqueness, router advertisements and upstream service consumer-owned.

## Rationale

Proxmox accepts dynamic forms but cloud-init 25.1.4 does not render them uniformly: ENI maps
SLAAC to autoconfiguration, netplan maps dynamic IPv6 to DHCPv6, and networkd renders no
specific SLAAC configuration. All render static address/gateway. The pinned provider does not
validate these forms. Requiring a gateway would exclude networks using router advertisements;
automatic connection selection would silently redirect existing consumers who add IPv6.

## Consequences

The [VM interface/lifecycle](../../tofu/modules/proxmox-linux-vm/README.md#static-ipv6) owns
addressing syntax, reboot/new-instance/host-key warnings and the distinction between removing a
declaration and removing all guest IPv6. Provider replacement for these updates blocks adoption
pending review. Mocks prove mapping, not runtime configuration or routing. Full IPv4-mode
interactions still need lifecycle evidence.

## References

- [DHCP/host decision](0012-dhcp-primary-attachment-addressing.md)
- [Evidence requirements](../../CONTRIBUTING.md#component-evidence-requirements)
- [Proxmox cloud-init IPv6 address and gateway format](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Network.pm#L170-L205)
- [Proxmox IPv6 configuration values](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L634-L644); [Proxmox address format accepting IPv4, IPv6, or DNS names](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L755-L765); [Proxmox list formats validating each element](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L991-L1004)
- [Proxmox cloud-init IPv6 subnet rendering](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L566-L578)
- [Proxmox cloud-init nameserver format](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer.pm#L825-L832)
- [`bpg/proxmox` v0.111.1 IPv6 IP configuration schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L927-L950)
- [`bpg/proxmox` v0.111.1 IP configuration encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/vms/custom_cloud_init.go#L80-L102)
- [cloud-init 25.1.4 dynamic IPv6 subnet types](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/net/__init__.py#L22-L27)
- [cloud-init 25.1.4 ENI IPv6 rendering](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/net/eni.py#L449-L470)
- [cloud-init 25.1.4 netplan IPv6 rendering](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/net/netplan.py#L108-L125)
- [cloud-init 25.1.4 systemd-networkd subnet rendering](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/net/networkd.py#L152-L186)
