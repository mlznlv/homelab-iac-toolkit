# ADR 0014: Constrain additional VM attachment retirement on the pinned provider

Status: Accepted. Supersedes [ADR 0011](0011-multiple-vm-network-attachments.md).

## Decision

- Retain ADR 0011's ordered additional interfaces, limit, fields, MAC output, primary-only
  gateway/connection source and exclusions in the [VM
  interface](../../tofu/modules/proxmox-linux-vm/README.md#additional-network-attachments).
- Support initial declaration, append and retained-slot bridge/VLAN/MAC/address updates;
  preserve VM, primary configuration and MAC unless separately changed.
- Exclude all removal, clearing, reorder, address retirement and removal/re-addition, even for
  addressless tails; require consumer plan review rather than promise history-sensitive
  validation from current inputs.
- Require case-insensitive uniqueness of declared MACs across all attachments;
  assigned/retained/network-wide uniqueness is not locally guaranteed.
- Require supported-transition and subsequent no-change evidence with source-grounded read-back;
  keep counterexamples visible and repeat the gate on provider upgrades.
- Restore retirement only through a later decision with exact-build cleanup/read-back evidence
  for every excluded transition, without VM recreation or hidden cleanup.

## Rationale

PR #102's real-provider synthetic-state plans and pinned source showed retired `ipconfigN` is
not deleted and is read back, producing recurring differences and potential repeated
rebuild/reboot. Mocked removal or one in-place plan misses this. A uniform restriction is safer
than asking consumers to reconstruct each slot's address history. Blocking useful append/update
or removing static addressing entirely was unnecessary; direct API cleanup would create a second
lifecycle owner.

## Consequences

The [VM
lifecycle](../../tofu/modules/proxmox-linux-vm/README.md#attachment-retirement-is-unsupported)
owns the plan-review warnings, MAC continuity limits and destructive replacement alternative.
Repeated apply, ignored differences or disabled reboot are not remedies. ADR 0012/0013 remain
accepted because they update retained primary `ipconfig0`, not retire it, and still require
convergence evidence. Restored retirement needs enabled upstream tests or equivalent update/read
evidence covering address removal, addressed tail/middle removal, reorder, clearing and
re-addition. Finished module tests gate Developer acceptance, not acceptance of this decision.

## References

- [Evidence requirements](../../CONTRIBUTING.md#component-evidence-requirements)
- [PR #102 exact-provider plan matrix and synthetic-state method](https://github.com/mlznlv/proxmox-iac-toolkit/pull/102)
- [v0.111.1 non-empty IP configuration encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/vms/custom_cloud_init.go#L80-L102)
- [v0.111.1 IP configuration read-back](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L5060-L5131); [v0.111.1 initialization rebuild/reboot flags](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6592-L6684); [v0.111.1 network-device deletion, distinct from IP configuration](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6821-L6847); [v0.111.1 cloud-init rebuild request](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L7008-L7012); [`bpg/proxmox` v0.111.1 eight cloud-init IP configurations](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L892-L957); [`bpg/proxmox` v0.111.1 `reboot_after_update` default](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L48)
- [`bpg/proxmox` v0.111.1 positional network-device schema and limits](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/network/schema.go#L75-L162)
- [`bpg/proxmox` v0.111.1 network devices read back by slot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/network/network.go#L108-L182)
- [Proxmox MAC address assignment](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Network.pm#L216-L219)
- [Proxmox device unplug on MAC address or model change](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer.pm#L5114-L5130)
- [Proxmox cloud-init network data by slot and MAC address](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L527-L579); [Proxmox cloud-init instance identifier digest](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L603-L608)
- [cloud-init 25.1.4 new-instance detection](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/stages.py#L535-L546); [cloud-init 25.1.4 network configuration applied only for a new instance by default](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/stages.py#L1078-L1090)
- [cloud-init 25.1.4 default network update events](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/sources/__init__.py#L277-L282)
- [cloud-init 25.1.4 SSH module frequency](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/config/cc_ssh.py#L32); [cloud-init 25.1.4 SSH host-key deletion default](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/config/cc_ssh.py#L99-L106)
- [Debian 13 cloud-init package version](https://sources.debian.org/src/cloud-init/25.1.4-1+deb13u1/)
