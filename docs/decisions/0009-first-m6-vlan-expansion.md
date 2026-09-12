# ADR 0009: Adopt optional access-VLAN tagging as the first M6 expansion

## Status

Accepted

## Context

M6 requires the smallest useful Proxmox expansion beyond the initial Linux VM slice. A consumer needs additional VM data disks, but the supported `bpg/proxmox` resource path does not currently establish safe reconciliation of an added managed disk with disks inherited from a clone template. In the exact locked provider source for `v0.111.1`, revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`, the acceptance test for cloning with an additional disk is disabled because its expected inherited-disk size is missing. The alternative experimental cloned-VM resource uses a different ownership model, omits capabilities required by the existing slice, and requires VM recreation when replacing the established resource family.

Optional access-VLAN tagging is a narrower demonstrated need that the existing `proxmox_virtual_environment_vm` network device exposes without another resource family. The provider represents no tag with an internal zero default, while Proxmox accepts tags from 1 through 4094 and has a running-VM network update path for changing a tag. These sources establish the basis for a public interface and an implementation evidence gate; they are source inspection, not live toolkit evidence.

This decision operates within the accepted [public toolkit and private deployment boundary](0001-public-toolkit-private-deployment-boundary.md), [lifecycle and orchestration ownership](0002-lifecycle-orchestration-ownership.md), [local validation, Task, and CI security boundary](0004-local-validation-task-ci-security-boundary.md), and [established Linux VM slice](0006-guest-agent-channel-at-creation.md).

## Decision

Adopt optional consumer-controlled access-VLAN tagging on the existing single-NIC `proxmox-linux-vm` capability as the first implementable M6 expansion.

The public input is `network_vlan_id`. It has nullable-integer semantics, defaults to `null`, and accepts whole numbers from `1` through `4094`. `null` is the only public untagged or disabled value; the provider's internal zero sentinel is not exposed as a toolkit value.

The input configures the existing single Proxmox network attachment on the existing `proxmox_virtual_environment_vm` resource. Adding, changing, or removing the VLAN tag must preserve that VM resource rather than replace it. Before implementation can be accepted, its pull request records provider-level evidence for this behavior from the exact locked provider build, separately from module or mock-provider contract tests. A later supported provider that plans replacement for a VLAN-only change is blocked pending Architecture review.

OpenTofu owns the network attachment and optional tag. Consumers own the bridge and VLAN values, pre-existing Proxmox bridge configuration, upstream switching, routing, topology, and consistency with their declared static IPv4 settings. Ansible does not acquire guest-network ownership.

The existing one-NIC, static-IPv4, gateway, DNS, and `connection` contracts remain unchanged. VLAN creation, bridge configuration or discovery, trunks, multiple NICs, DHCP, IPv6, network orchestration, guest VLAN configuration, and private topology remain deferred.

Normal public validation remains credential-free and does not claim successful live PVE application, connectivity, routing, bridge or switch correctness, uninterrupted SSH, or zero-downtime updates. Exact input documentation, examples, and validation implementation remain in their owning component and validation sources rather than this ADR.

## Consequences

- Existing consumers remain untagged unless they deliberately provide a VLAN identifier.
- The capability extends the existing module root and resource family without adding a module, role, example, or orchestration layer.
- A VLAN update can interrupt connectivity or make the guest unreachable when consumer-owned network configuration is inconsistent.
- Module and mock-provider tests can establish public input and resource-address structure, but cannot alone establish the provider's in-place lifecycle behavior.
- Implementation acceptance and later provider upgrades require reviewable provider-level no-replacement evidence.
- Additional VM data disks remain Architecture-blocked in [Issue #80](https://github.com/mlznlv/homelab-iac-toolkit/issues/80) until the supported provider preserves inherited disks and supplies predictable additional-disk lifecycle behavior.

## Alternatives considered

- **Select additional VM data disks first:** deferred as blocked. The current supported resource path has a disabled failing acceptance test for the required clone-plus-additional-disk behavior, so Architecture cannot safely assign create, update, or remove semantics without risking inherited-root-disk reconciliation.
- **Redesign the module around the experimental cloned-VM resource:** rejected. It changes the established lifecycle and resource family, lacks current initialization and guest-agent capabilities, and requires VM recreation.
- **Expose provider zero as the public untagged value:** rejected. `null` expresses absence without leaking a provider sentinel, while 1 through 4094 match the platform tag range.
- **Add trunks or multiple NICs with VLAN tagging:** rejected. They create broader interface, ordering, and topology decisions that are unnecessary for the first M6 increment.
- **Allow provider-planned VM replacement for tag changes:** rejected. A VLAN-only network policy change must not silently become destructive VM recreation.

## Sources

- [`bpg/proxmox` v0.111.1 network-device VLAN schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/network/schema.go#L141-L146)
- [`bpg/proxmox` v0.111.1 network-device update path](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6817-L6847)
- [`bpg/proxmox` v0.111.1 disabled clone-with-additional-disk test](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/fwprovider/test/resource_vm_disks_test.go#L1159-L1207)
- [`bpg/proxmox` v0.111.1 experimental cloned-VM limitations](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/docs/resources/cloned_vm.md#L1-L35)
- [`bpg/proxmox` v0.111.1 cloned-VM migration and recreation](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/docs/guides/migration-vm-clone.md#L374-L405)
- [Proxmox QEMU network VLAN range](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Network.pm#L87-L92)
- [Proxmox running-VM network tag update path](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer.pm#L5106-L5185)
