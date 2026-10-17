# ADR 0017: Qualify guest distributions separately for VM templates, LXC, and Ansible roles

Status: Accepted.

## Decision

- Qualify VM templates, LXC and each Ansible role independently; never infer support across
  tracks, roles or their composition. Evidence may be reused only as input for the same exact
  identity, with separate claims.
- Allow consumer-selected VM templates under the unchanged contract without a toolkit claim.
  Naming a target needs qualification; changed bootstrap/module behavior needs a capability
  decision and exact-provider evidence.
- Give Debian LXC no distribution extension point: another target needs its own
  type/plugin/template/authorization/lifecycle/placement decision. Generic role modules do not
  widen a role's declared contract.
- Require [Compatibility's qualification record and requalification
  rules](../compatibility.md#guest-distribution-qualification); runtime claims require an
  accepted isolated live path, not consumer anecdotes.
- Permit no privileged container, extra feature beyond nesting, `root@pam`-only operation or
  interactive escalation through qualification; each needs a decision.
- Treat distribution changes as new guests with consumer data migration/reviewed retirement,
  never conversion, import, state rewrite or automatic migration.
- Start expansion only from a demonstrated specific-release/repeatable-workload need current
  targets cannot meet, recorded sanitized in an Architecture issue; need, milestone
  prerequisites, accepted target decision and PO spec are separate gates.

## Rationale

VM cloud-init, Proxmox container setup and role packaging have different behavior and owners.
Proxmox detects LXC distribution, warns on a declared mismatch and stores the detected type;
type selection alone does not enable another target. Its pinned Debian plugin rejects releases
before 4 and warns above 14. Setup runs on every start. VM templates choose cloud-init format,
per-instance package upgrades and default-user privilege; those facts require target-specific
review. Popularity, a desired catalog or a planned runner supplies no workload to qualify.

## Consequences

Template changes destroy the prior VM/disks or container/rootfs. Release upgrades inside guests
remain consumer-owned, not detected/performed by the toolkit; qualifying new guests does not
qualify upgrade paths or inherited package state. An upgraded guest needs a separately qualified
path, including container setup against its upgraded filesystem. Record target-specific
reapplication effects. Bootstrap that competes with ongoing Ansible ownership needs a new
decision.

No target, component, OS selector or distribution hierarchy is added. Existing claims remain
until their next requalification trigger. Target changes reconcile the target ADR,
Compatibility, component README, consumer workflow if affected, Architecture if
boundaries/placement change, and changelog/migration. Narrowing or withdrawal describes
destructive consumer replacement, not conversion.

## References

- [Qualification record and triggers](../compatibility.md#guest-distribution-qualification)
- [Expansion request #104](https://github.com/mlznlv/proxmox-iac-toolkit/issues/104)
- [Proxmox container setup plugins by type](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup.pm#L25-L38); [Proxmox container setup detecting the distribution and warning on a different declared type](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup.pm#L100-L127)
- [Proxmox Debian setup plugin release limits](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Debian.pm#L16-L59)
- [Proxmox container create detecting the distribution before writing the configuration](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/API2/LXC.pm#L594-L598)
- [Proxmox container setup on every start](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/lxc-pve-prestart-hook#L183-L184)
- [re-applying init, network, hostname, DNS, and timezone](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L698-L710)
- [`bpg/proxmox` v0.111.1 accepted container types](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/validators.go#L45-L59)
- [`bpg/proxmox` v0.111.1 container type read-back](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3334-L3363); [`bpg/proxmox` v0.111.1 container type update and reboot request](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L4062-L4080)
- [`bpg/proxmox` v0.111.1 replacement-forcing VM clone source](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L622-L628)
- [Proxmox VM clone copying the template's configuration](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/API2/Qemu.pm#L4510-L4579)
- [Proxmox VM cloud-init format default](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L94-L110); [Proxmox VM cloud-init user data, default user, and package upgrade](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L145-L189)
- [cloud-init 25.1.4 merging the declared user into the distribution's default user](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/distros/ug_util.py#L165-L238)
- [cloud-init 25.1.4 package upgrade once per instance](https://github.com/canonical/cloud-init/blob/ea53a592be3df61059bd80fc0e32dff94a037906/cloudinit/config/cc_package_update_upgrade_install.py#L24-L27)
