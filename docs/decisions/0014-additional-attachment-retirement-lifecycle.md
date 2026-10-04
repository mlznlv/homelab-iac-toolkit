# ADR 0014: Constrain additional VM attachment retirement on the pinned provider

## Status

Proposed

## Context

ADR 0011 accepted ordered additional VM network attachments with optional static IPv4 configuration. Implementation evidence in PR #102 against the exact locked `bpg/proxmox` build, v0.111.1 at revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`, exposed a lifecycle property that the earlier source review did not make safe enough for a public convergence claim.

The provider removes network-device slots that disappear from the planned device list, but it does not clear retired Proxmox `ipconfigN` entries when an attachment or its declared address disappears. A refresh reads the retired entry back, so a subsequent plan proposes removing it again. On the pinned provider, an initialization change rebuilds cloud-init and can reboot a running VM. Repeating plan/apply therefore does not converge for a retired addressed slot and can repeatedly trigger disruptive cloud-init work.

This behavior is not a mock-test artifact. PR #102 reproduced it through provider-level plan evidence for the exact locked provider build. Normal public validation still does not apply the change to a live Proxmox host.

A reusable toolkit must not describe a non-converging lifecycle as ordinary supported removal. The multi-attachment capability can still provide useful additive and in-place network expansion without making retirement semantics stronger than the provider supports.

## Decision

Keep the ordered additional-network-attachment interface from ADR 0011, including optional static IPv4 on additional attachments, but narrow its supported lifecycle on the pinned provider.

The supported lifecycle is append-and-update:

- consumers may append new additional attachments after the existing final slot;
- consumers may change the bridge, VLAN, declared MAC address, or one non-null static IPv4 address to another on an existing slot;
- consumers keep the order and count of existing additional attachments stable once those slots have been created.

Removing an additional attachment, reordering existing attachments, or changing an additional attachment from an addressed state to an addressless state is not a supported convergent operation on the pinned provider. The module does not claim that repeated plan/apply will settle such a change, and consumers must not use repeated apply as a cleanup mechanism.

A consumer that must retire or reorder an existing slot chooses an explicit migration outside the normal capability contract: preserve the slot, rebuild/replace the VM under a reviewed migration, or wait for a supported provider path that can clear retired `ipconfigN` entries. The toolkit does not automate direct Proxmox mutation to work around provider state because that would create a competing lifecycle owner.

The implementation remains positional. Appending a new slot is supported because it does not retire an existing `ipconfigN`; changing an existing non-null address in place is supported because the same slot remains declared. The provider-level evidence gate for implementation must cover these supported transitions and must accurately retain the non-convergence evidence for unsupported retirement transitions.

Declared MAC addresses must be unique across the additional attachments. This is locally decidable, avoids an invalid or ambiguous guest-network identity, and is added to the module contract. When the primary attachment later gains a declarable MAC under ADR 0012, duplicate validation extends across the primary and additional declared values.

DHCP and static IPv6 on the primary attachment remain governed by ADR 0012 and ADR 0013. They use `ipconfig0` and do not relax this decision for additional-attachment retirement.

This decision supersedes the removal, de-addressing, and reordering lifecycle claims in ADR 0011. The rest of ADR 0011 remains the basis of the multiple-attachment interface until a later decision replaces it.

## Consequences

- The capability can ship without claiming convergence for a lifecycle the pinned provider cannot perform.
- Existing single-NIC consumers remain unchanged.
- Consumers can add interfaces and make ordinary in-place changes, which covers the demonstrated expansion path without requiring direct Proxmox mutation.
- Consumers that need to shrink or reorder the interface set must plan an explicit migration instead of expecting the module to clean retired cloud-init state.
- The public interface is more conservative than the provider schema, by design.
- A future provider build that demonstrably clears retired `ipconfigN` entries may justify a new Architecture decision that restores supported retirement.
- Mocked module tests remain contract evidence only; the provider-level plan evidence in the implementation PR remains necessary for lifecycle claims.

## Alternatives considered

- **Ship removal as supported and document the repeated diff:** rejected. A known non-converging plan, coupled to repeated cloud-init rebuild/reboot behavior, is not an acceptable normal lifecycle contract.
- **Automatically mutate Proxmox to delete retired `ipconfigN`:** rejected. It bypasses the provider and creates a second lifecycle owner.
- **Remove static addressing from additional attachments entirely:** rejected for now. Stable-slot static addressing itself works and is already an accepted useful capability; the defect is retirement, not declaration or in-place change.
- **Block the entire multi-attachment capability:** rejected. Append-and-update behavior has provider-level evidence and provides reusable value without depending on the broken retirement path.
