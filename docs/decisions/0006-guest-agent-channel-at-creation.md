# ADR 0006: Adopt the coordinated first slice with the guest-agent channel present from creation

Status: Accepted. Supersedes [ADR 0005](0005-first-reusable-toolkit-slice.md).

## Decision

- Keep the coordinated full-clone VM and independently usable guest-agent role
  as the first slice; retain provider/backend and composition ownership boundaries.
- Attach the guest-agent channel by default, with an explicit opt-out, while
  always disabling provider IP waiting and publishing no agent-discovered address.
- Let Ansible install/start the agent; honor boot-enabling only where packaging
  supports it. Ordinary inventory creates no dependency on OpenTofu state.
- Retain `stop_on_destroy` default true with an explicit false shutdown override,
  and required non-sensitive `connection` metadata including `ssh_port` default 22.
- Keep compatibility explicit and public evidence credential-free; exact tool
  constraints, further input names and test mechanisms remain owning-file details.

## Rationale

The former sequence disabled the device the Debian service needs, then asked the
role to start it. Its static unit cannot be enabled conventionally; enabling the
channel later also needs stop/start. Separating channel presence from provider
waiting removes that circular dependency. Waiting could otherwise stall each
apply/refresh for the provider's fifteen-minute timeout.

Unconditional channel exposure would remove consumer choice. Exposing IP waiting
would restore the dependency. Installing the agent through cloud-init would put
package/service ownership in the infrastructure layer instead of exercising Ansible.

## Consequences

One apply followed by guest configuration suffices without later reconciliation.
The absent-agent window has operation-specific ACPI/backup/query consequences;
the [VM lifecycle guide](../../tofu/modules/proxmox-linux-vm/README.md#guest-agent-and-destroy)
owns those warnings, channel opt-out and destructive-stop trade-offs. Enabling
the channel no longer requires a pre-existing running agent, withdrawing ADR 0005's
circular requirement. These expectations come from pinned source, not a live run.

## References

- [Role interface](../../ansible/roles/qemu_guest_agent/README.md)
- [Compatibility](../compatibility.md)
- [`QemuServer.pm` L3459-3471](https://github.com/proxmox/qemu-server/blob/9cba97b4f2d9244ea40ddac5130bc4d147bb1dc3/src/PVE/QemuServer.pm#L3459-L3471)
- [`vmconfig_update_agent`, L5205-5227](https://github.com/proxmox/qemu-server/blob/9cba97b4f2d9244ea40ddac5130bc4d147bb1dc3/src/PVE/QemuServer.pm#L5205-L5227)
- [`QemuServer.pm` L6266-6273](https://github.com/proxmox/qemu-server/blob/9cba97b4f2d9244ea40ddac5130bc4d147bb1dc3/src/PVE/QemuServer.pm#L6266-L6273)
- [`qga_check_running`, Agent.pm L82-89](https://github.com/proxmox/qemu-server/blob/9cba97b4f2d9244ea40ddac5130bc4d147bb1dc3/src/PVE/QemuServer/Agent.pm#L82-L89)
- [`guest_fs_freeze_applicable`, Agent.pm L309-322](https://github.com/proxmox/qemu-server/blob/9cba97b4f2d9244ea40ddac5130bc4d147bb1dc3/src/PVE/QemuServer/Agent.pm#L309-L322)
- [`qemu-guest-agent.service`](https://salsa.debian.org/qemu-team/qemu/-/blob/104fbbd5f207885b9d6cbc2ff330bb50eeec4390/debian/qemu-guest-agent.service)
- [`qemu-guest-agent.udev`](https://salsa.debian.org/qemu-team/qemu/-/blob/104fbbd5f207885b9d6cbc2ff330bb50eeec4390/debian/qemu-guest-agent.udev)
- [`systemd_service.py` L502-545](https://github.com/ansible/ansible/blob/v2.21.3/lib/ansible/modules/systemd_service.py#L502-L545)
- [`bpg/proxmox` v0.111.0 argument reference L129-145](https://github.com/bpg/terraform-provider-proxmox/blob/v0.111.0/docs/resources/virtual_environment_vm.md#L129-L145)
