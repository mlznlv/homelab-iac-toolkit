# ADR 0009: Adopt optional access-VLAN tagging as the first M6 expansion

Status: Accepted.

## Decision

- Add optional access-VLAN tagging to the existing VM module/resource family.
- Use nullable integer `network_vlan_id`: null means an attached untagged device; tagged values
  are 1–4094, not the provider's internal zero sentinel.
- Require VLAN add/change/remove to preserve the VM, with exact-build provider evidence separate
  from module mocks before implementation acceptance/upgrades.
- Keep bridge/VLAN selection, upstream switching/routing and matching addressing consumer-owned;
  add no guest-network or orchestration owner.
- Keep additional data disks deferred until safe inherited-disk reconciliation and predictable
  lifecycle are evidenced in [#80](https://github.com/mlznlv/proxmox-iac-toolkit/issues/80).

## Rationale

VLAN tagging is a narrow useful change on the existing resource. The locked provider's
clone-plus-disk test is disabled over missing inherited-disk size; the experimental cloned-VM
resource lacks required initialization/agent behavior and migrating to it recreates the VM.
Broader trunks/multiple-NIC decisions were not needed to solve the first expansion.

## Consequences

Existing consumers remain untagged. VLAN changes interrupt the virtual link and require consumer
network consistency; [the VM README](../../tofu/modules/proxmox-linux-vm/README.md#vlan-tagging)
owns the interface and warning. Replacement for a tag-only change blocks adoption pending
Architecture review. [Compatibility](../compatibility.md) separates these provider expectations
from unobserved live connectivity.

## References

- [Component evidence gate](../../CONTRIBUTING.md#component-evidence-requirements)
- [`bpg/proxmox` v0.111.1 network-device VLAN schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/network/schema.go#L141-L146)
- [`bpg/proxmox` v0.111.1 network-device update path](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6817-L6847)
- [`bpg/proxmox` v0.111.1 disabled clone-with-additional-disk test](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/fwprovider/test/resource_vm_disks_test.go#L1159-L1207)
- [`bpg/proxmox` v0.111.1 experimental cloned-VM limitations](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/docs/resources/cloned_vm.md#L1-L35)
- [`bpg/proxmox` v0.111.1 cloned-VM migration and recreation](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/docs/guides/migration-vm-clone.md#L374-L405)
- [Proxmox QEMU network VLAN range](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Network.pm#L87-L92)
- [Proxmox running-VM network tag update path](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer.pm#L5137-L5186)
