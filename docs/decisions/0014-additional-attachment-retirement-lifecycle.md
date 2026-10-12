# ADR 0014: Constrain additional VM attachment retirement on the pinned provider

## Status

Accepted

## Context

[ADR 0011](0011-multiple-vm-network-attachments.md) accepted ordered additional VM network attachments with optional static IPv4 configuration. Implementation evidence in [PR #102](https://github.com/mlznlv/proxmox-iac-toolkit/pull/102), reviewed under [Issue #103](https://github.com/mlznlv/proxmox-iac-toolkit/issues/103), against the exact locked `bpg/proxmox` build, v0.111.1 at revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`, exposed a lifecycle property that the earlier source review did not make safe enough for a public convergence claim.

The provider removes network-device slots that disappear from the planned device list, but it does not clear retired Proxmox `ipconfigN` entries when an attachment or its declared address disappears. A refresh reads the retired entry back, so a subsequent plan proposes removing it again. On the pinned provider, an initialization change rebuilds cloud-init and can reboot a running VM. Repeating plan/apply therefore does not converge for a retired addressed slot and can repeatedly trigger disruptive cloud-init work.

This behavior is not a mock-test artifact. PR #102 executed credential-free plans with the real locked provider, refresh disabled, and fictional synthetic prior states. Its later-plan cases modeled the retained entries returned by the inspected read path; they did not execute apply or live refresh. The plans and pinned update/read source substantiate the defect and in-place planning behavior, not successful live application or guest convergence.

A reusable toolkit must not describe a non-converging lifecycle as ordinary supported removal. The multi-attachment capability can still provide useful additive and in-place network expansion without making retirement semantics stronger than the provider supports.

This decision preserves the [public/private boundary](0001-public-toolkit-private-deployment-boundary.md), [lifecycle ownership](0002-lifecycle-orchestration-ownership.md), [credential-free validation boundary](0004-local-validation-task-ci-security-boundary.md), and [existing VM resource family](0006-guest-agent-channel-at-creation.md). It changes neither those boundaries nor the provider constraint.

## Decision

Keep the ordered additional-network-attachment interface from ADR 0011, including optional static IPv4 on additional attachments, but narrow its supported lifecycle on the pinned provider.

The supported lifecycle is append-and-update:

- consumers may initially declare attachments and append new ones after the existing final slot;
- consumers may change the bridge, VLAN, or declared MAC address, add a static IPv4 address, or change one non-null static IPv4 address to another on an existing retained slot;
- consumers keep existing slots in the same order; the count may grow but must not shrink.

Supported changes must preserve the VM resource and the primary `net0` configuration and MAC unless a separate accepted primary-attachment change is deliberately requested. Moving a logical interface to another slot is not identity-preserving.

Removing any additional attachment, clearing the list after attachments exist, middle removal, reordering, removing an existing address, and removal followed by re-addition are outside the supported lifecycle. This uniform restriction also excludes retirement of an addressless attachment, although PR #102 records an in-place plan with unchanged cloud-init configuration for addressless tail removal: the public contract does not require consumers to distinguish historical addressing cases before deciding whether retirement is supported.

This is a public usage contract, not a promise of plan-time historical validation. Current inputs cannot determine prior order, count, or address history. The module prominently documents unsupported transitions and recurring-diff/reboot risk; consumer review of configuration and `tofu plan` precedes explicit apply. It must not present a merely in-place retirement plan as supported or suggest repeated apply, ignored initialization differences, or disabled reboot as a remedy.

A consumer needing retirement preserves existing slot configuration, waits for an evidenced provider remedy, or plans an explicit reviewed VM rebuild/replacement outside this capability's normal update contract. Replacement destroys the old VM and risks loss of guest data; it is not a toolkit cleanup operation. The toolkit adds no direct Proxmox mutation, automatic recovery, or competing lifecycle owner.

The implementation remains positional. Appending or updating a retained slot does not retire an existing `ipconfigN`. Implementation may ship only after documentation, tests, and provider evidence agree with this restricted contract. Evidence covers every supported transition, unchanged primary configuration and MAC, and a subsequent no-op plan with source-grounded post-update state. Unsupported retired-entry counterexamples remain visible separately. Module/mock tests prove mapping and validation, not provider convergence or runtime MAC continuity; exact-provider plans and pinned update/read paths establish provider-level expectations without claiming live execution. Architecture acceptance does not require finished module tests; Developer acceptance does. Provider upgrades re-evaluate this evidence.

Non-null declared MAC addresses must be unique, compared case-insensitively, across additional attachments. When the primary MAC input from [ADR 0012](0012-dhcp-primary-attachment-addressing.md) is implemented, the same rule includes the declared primary MAC. Undeclared provider-assigned values and network-wide collisions are not locally decidable guarantees. Removing a MAC declaration does not request a new MAC: the evidenced optional/computed provider field can retain the observed value. Removing an attachment relinquishes its MAC; unsupported re-addition promises neither reuse nor a different MAC.

[ADR 0012](0012-dhcp-primary-attachment-addressing.md) and [ADR 0013](0013-static-ipv6-primary-attachment.md) remain accepted. They update the retained primary `ipconfig0`, whose IPv4 mode remains required, rather than retire the whole entry. Their implementation evidence must still establish correct update/read and subsequent-plan behavior; this decision does not excuse recurring differences on that path.

Restoring retirement requires a later Architecture decision supported by an exact provider build that deletes or clears retired `ipconfigN`, reads back the intended configuration, and produces a subsequent no-op plan for address removal, addressed tail removal, middle removal/reordering, clearing, and removal/re-addition without VM recreation or hidden cleanup. Enabled upstream tests or equivalent reviewed evidence must support actual update/read semantics, not only mocked removal or a first in-place plan. No provider upgrade is selected here.

ADR 0011 is marked Superseded without rewriting its historical decision text. This decision incorporates its unchanged interface, attachment limit, MAC output, primary-only gateway and connection source, ownership, and exclusions; it is authoritative for the revised lifecycle and MAC uniqueness rule.

## Consequences

- The capability remains implementable, but PR #102 cannot ship its former supported-retirement claims. Issue #98 must use the restricted criteria before implementation acceptance.
- Existing single-NIC consumers remain unchanged.
- Consumers can add interfaces and make ordinary in-place changes, which covers the demonstrated expansion path without requiring direct Proxmox mutation.
- Consumers that need to shrink or reorder the interface set must plan an explicit migration instead of expecting the module to clean retired cloud-init state.
- The public interface is more conservative than the provider schema, by design.
- A future provider build that demonstrably clears retired `ipconfigN` entries may justify a new Architecture decision that restores supported retirement.
- Supported address changes retain the existing cloud-init rebuild/reboot, new-instance, and possible SSH host-key regeneration warnings. Bridge, VLAN, and MAC changes can interrupt connectivity.
- Normal public validation remains credential-free and non-destructive. No live-testing requirement or claim of hot-plug success, runtime MAC continuity, guest configuration, reachability, or routing is introduced.

## Alternatives considered

- **Ship removal as supported and document the repeated diff:** rejected. A known non-converging plan, coupled to repeated cloud-init rebuild/reboot behavior, is not an acceptable normal lifecycle contract.
- **Automatically mutate Proxmox to delete retired `ipconfigN`:** rejected. It bypasses the provider and creates a second lifecycle owner.
- **Remove static addressing from additional attachments entirely:** rejected for now. Stable-slot static addressing has evidenced in-place planning and is already an accepted useful capability; the defect is retirement, not declaration or in-place change.
- **Block the entire multi-attachment capability:** rejected. Append-and-update behavior has provider-level evidence and provides reusable value without depending on the broken retirement path.
- **Support selected addressless removals:** deferred. A narrower exception needs its own reviewed history-sensitive contract; the uniform rule is easier to review safely.

## Sources

- [PR #102 exact-provider plan matrix and synthetic-state method](https://github.com/mlznlv/proxmox-iac-toolkit/pull/102)
- [v0.111.1 non-empty IP configuration encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/vms/custom_cloud_init.go#L80-L102)
- [v0.111.1 IP configuration read-back](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L5060-L5131)
- [v0.111.1 initialization rebuild/reboot flags](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6592-L6684)
- [v0.111.1 network-device deletion, distinct from IP configuration](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6821-L6847)
- [v0.111.1 cloud-init rebuild request](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L7008-L7012)
