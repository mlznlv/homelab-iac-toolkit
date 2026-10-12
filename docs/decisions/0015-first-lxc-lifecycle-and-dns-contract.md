# ADR 0015: Constrain the first LXC capability to evidenced lifecycle and explicit consumer DNS

## Status

Accepted

Supersedes [ADR 0010](0010-first-reusable-lxc-capability.md). Its historical decision text is retained; this record carries forward the unchanged capability and replaces its shrink, post-create nesting, and incomplete DNS assumptions.

## Context

The implementation evidence gate for the first LXC capability exposed three gaps in ADR 0010. The reviewed implementation in [PR #107](https://github.com/mlznlv/homelab-iac-toolkit/pull/107) was at commit `79fb02eadf9880358641ad7f5fa3dc3052a89b83`. It uses the supported `bpg/proxmox` line and locked v0.111.1 build, source revision `b22fe919fc34476b232191b69c8907f0c1aa5bea`. No provider upgrade is selected by this decision; executable constraints and locks remain authoritative.

- **Shrink is not a working replacement contract.** The implementation author's refresh-disabled real-provider plan against synthetic prior state plans a root-filesystem decrease as an update with no replacement path. The provider intends replacement on its nested disk block, but its SDK v2.40.1 diff path does not propagate that flag to the changed size field when the block count is unchanged. The provider's update path then refuses the smaller size. Source intent alone did not establish the earlier replacement claim.
- **Creation and later nesting changes have different authorization.** Creation sends nesting alone, only when enabled. A feature update also emits false non-nesting flags. The inspected Proxmox permission path treats absent-to-false flags as changes, which are restricted to the exact `root@pam` identity. A plan can show an update without establishing that the consumer can apply it.
- **Required DNS servers do not prevent node-domain inheritance.** Proxmox falls back independently for nameservers and the search domain. The provider omits an empty domain on create and deletes it on update; neither is a no-search mechanism. A declared non-empty domain is sent on create/update and read back from the container configuration.

The provider's size-only growth path requests no reboot; the earlier ADR grouped it with rebooting updates incorrectly. The provider also sends zero swap when no swap input is exposed. These observations correct the documented consequences without adding another capability.

The plans above were executed by the implementation author without refresh or apply. The provider, SDK, and Proxmox source paths were independently inspected for Architecture; their revisions are linked below. No refusal, resize, feature update, DNS setup, or guest behavior was executed against Proxmox. Source inspection is not a live compatibility claim.

## Decision

Retain the first LXC capability and constrain it to the lifecycle and DNS ownership supported by the evidence:

- One unprivileged Debian container, created from a consumer-supplied template volume, remains a separate module at `tofu/modules/proxmox-linux-container/` using `proxmox_virtual_environment_container`. The PVE target, provider line, static IPv4 network, metadata-only `connection` output, creation-only root SSH keys, start-on-boot, bounded provider read wait, and destroy policy remain unchanged.
- Support root-filesystem growth in place. Do not support shrinking or promise automatic replacement for a decrease. The consumer must reject a decrease during plan review; obtaining smaller storage requires explicit consumer-owned recreation and data preservation with its destructive consequences reviewed. The toolkit adds no replacement trigger, state rewrite, automatic recovery, or storage migration mechanism.
- Retain nesting enabled by default and the consumer's ability to disable it at creation. Post-create toggles are unsupported on this build. Consumers retain the creation-time value; the toolkit does not conceal a changed input with ignore-changes handling, adopt an elevated-identity requirement, or silently replace the container. Later-toggle support requires another Architecture decision based on sufficient provider lifecycle and authorization evidence.
- Require an explicit consumer-supplied, non-empty single DNS search domain as well as DNS servers. There is no toolkit default and no implicit node-domain inheritance. The domain is passed through the provider's existing DNS initialization interface; an explicit no-search mode remains deferred until a reliable provider path is evidenced.

All other ADR 0010 interface, lifecycle, ownership, and scope decisions are retained. In particular, template, datastore, node, and identifier changes remain destructive replacements; bootstrap-key changes remain ignored as an expressly accepted bootstrap-only boundary. Dedicated memory, network, DNS, and name updates reboot a running container on the pinned path; CPU and size-only root-filesystem growth do not request a reboot. Swap remains the documented zero provider default with no new input.

This decision operates within [ADR 0001](0001-public-toolkit-private-deployment-boundary.md), [ADR 0002](0002-lifecycle-orchestration-ownership.md), and [ADR 0004](0004-local-validation-task-ci-security-boundary.md). It changes neither the VM capability nor ongoing guest-configuration ownership. Input syntax and the implementation evidence gate belong in [Architecture](../architecture.md#first-reusable-lxc-capability); platform and evidence claims belong in [Compatibility](../compatibility.md#lxc-capability).

## Consequences

- Current-input validation cannot compare against prior size or nesting values. Plan review must reject shrinking and post-create nesting toggles; an update action alone does not establish support. Provider failures are surfaced, not hidden or repaired automatically.
- Smaller storage may require destruction of the existing container and its root filesystem. Protecting data and authorizing that separate procedure remain consumer responsibilities, not a supported automatic module transition.
- An explicit search domain removes the inspected node-domain fallback without prescribing a private domain. Consumers requiring no search domain are not supported by this first capability.
- The unsupported toggle does not become supported by granting elevated credentials. Creation-time nesting remains a consumer choice, and the template must work with that choice.
- Network, DNS, name, and memory updates may interrupt guest connectivity. The absence of a size-only growth reboot request is not a runtime availability guarantee.
- Architecture acceptance requires sufficient pinned lifecycle/source evidence, truthful limits, and reconciled durable documents. It does not wait for finished module tests. Developer acceptance separately requires credential-free module tests and exact-provider implementation evidence, including explicit-domain create/update/read behavior and the documented unsupported-operation counterexamples.
- Provider upgrades must re-evaluate this evidence before retaining the same compatibility claims. Re-enabling shrinking, later nesting toggles, or adding no-search behavior is not an incidental implementation fix.
- No live infrastructure, mandatory runtime test, credential tooling, new Ansible component, VM DNS redesign, or orchestration is introduced. Normal public validation remains credential-free and proves no guest convergence or live Proxmox compatibility.

## Alternatives considered

- **Continue promising shrink replacement from the provider's source intent:** rejected; the exact-build plan contradicts it and update refuses.
- **Force replacement or migrate state in the module:** rejected; this would introduce an unevidenced destructive workaround rather than the narrow growth-only contract.
- **Support later nesting changes by requiring `root@pam`:** rejected for this capability; the broader privilege boundary is unnecessary for creation and is not adopted for ongoing consumption.
- **Ignore later nesting changes:** rejected; unlike explicitly bootstrap-only SSH keys, concealing an attempted feature change would misrepresent the input.
- **Accept node-domain inheritance:** rejected; node-specific resolver configuration must not enter the reusable capability implicitly.
- **Use an empty domain or a no-search sentinel:** deferred; omission/deletion restores fallback, and no reliable supported no-search path has been established.
- **Upgrade the provider as a remedy:** deferred to a separate reviewed path; a different build does not acquire lifecycle evidence merely by existing.

## Sources

- [PR #107 exact-build plan report and three Architecture findings](https://github.com/mlznlv/homelab-iac-toolkit/pull/107#provider-level-lifecycle-evidence)
- [Provider shrink replacement intent](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L1182-L1228)
- [SDK v2.40.1 nested-block diff behavior](https://github.com/hashicorp/terraform-plugin-sdk/blob/e6c7dc42a51abcaf5b709a98720ba13ba0082021/helper/schema/schema.go#L1392-L1441)
- [Provider shrink refusal, growth, and mount-option-only reboot flag](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3662-L3710)
- [Provider creation-versus-update feature encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L2540-L2602)
- [Provider feature serialization](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/containers/containers_types.go#L323-L369)
- [Proxmox feature and DNS authorization](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC.pm#L1678-L1757)
- [Provider DNS-domain schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L543-L548)
- [Provider DNS-domain create request](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L2228-L2234)
- [Provider DNS-domain read-back](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L2940-L2946)
- [Provider DNS-domain update/delete and reboot request](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3832-L3851)
- [Proxmox independent nameserver and search-domain fallback](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L33-L59)
- [Proxmox DNS-name validation](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L673-L683)
- [Provider zero-swap default](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L75)
