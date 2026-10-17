# ADR 0012: Adopt consumer-owned DHCP addressing for the primary VM attachment

Status: Accepted.

## Decision

- Add explicit primary IPv4 DHCP while retaining static as default; static needs
  address/gateway, DHCP forbids them, and both require explicit DNS servers.
- Keep required `connection` shape; publish a supplied host in either mode,
  require it in DHCP, otherwise derive static IPv4. Never discover or wait for it.
- Add optional primary MAC with the additional-device syntax/validation, retaining
  consumer ownership of DHCP service, reservations, leases, naming and reachability.
- Require static/DHCP and primary-MAC updates to preserve the VM, with independent
  exact-build provider evidence and source-grounded subsequent no-change plans.
- Keep DHCP off additional attachments and retain the existing resource/ownership
  boundaries; connection-host-only changes are metadata, not infrastructure.

## Rationale

Proxmox renders primary `dhcp` as DHCPv4 and omits an explicit gateway. An unknown
lease cannot provide a declared connection host; agent discovery would need SSH
before Ansible installs the agent, recreating the dependency ADR 0006 removed.
Null output would merely move failure into inventory. Explicit DNS avoids node
resolver fallback. Multiple DHCP interfaces could introduce competing default routes.

## Consequences

The [VM guide](../../tofu/modules/proxmox-linux-vm/README.md#dhcp-addressing) owns
reservation prerequisites, host validation and mode/MAC-change disruption.
Mode changes can reboot, change addresses and regenerate host keys; declaring a
MAC supports first-boot reservations but changing it changes the guest's device.
Mock tests cannot prove lifecycle or a lease; unexpected replacement blocks
provider adoption pending Architecture review.

## References

- [ADR 0006](0006-guest-agent-channel-at-creation.md)
- [Retained-slot lifecycle](0014-additional-attachment-retirement-lifecycle.md)
- [Evidence requirements](../../CONTRIBUTING.md#component-evidence-requirements)
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
