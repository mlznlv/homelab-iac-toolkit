# ADR 0015: Constrain the first LXC capability to evidenced lifecycle and explicit consumer DNS

Status: Accepted. Supersedes [ADR 0010](0010-first-reusable-lxc-capability.md).

## Decision

- Retain ADR 0010's separate unprivileged Debian LXC capability and interface, including
  start-on-boot, static IPv4, root bootstrap keys and declared connection.
- Support root-filesystem growth only; shrinking needs deliberate consumer-owned recreation/data
  preservation, not an automatic replacement or recovery promise.
- Keep nesting default-enabled and configurable only at creation; do not hide later toggles,
  elevate credentials to support them, or replace implicitly.
- Require explicit nonempty single DNS search domain and servers, passed through without node
  inheritance; defer no-search until its provider path is evidenced.
- Retain destructive template/datastore/node/identifier replacement and ignore only later
  bootstrap-key changes. Ongoing key management stays guest configuration.
- Preserve exact-provider acceptance/upgrade gates and unsupported counterexamples; new shrink,
  nesting-toggle or no-search support requires a later decision.

## Rationale

PR #107 plans contradict the provider's intended shrink replacement: SDK nested block handling
loses the replacement flag and update refuses the smaller size. Nesting updates restate absent
non-nesting flags as false, triggering Proxmox's `root@pam` restriction; creation sends only
nesting. Required nameservers alone still inherit the node search domain. Empty/deleted domains
restore fallback. Source also corrects size-only growth to no reboot request and documents zero
swap. These are executed refresh-disabled plans and inspected source, not observed refusals.

## Consequences

The [LXC README](../../tofu/modules/proxmox-linux-container/README.md#lifecycle) owns input
syntax, lifecycle, bounded read wait, reboot/destruction and plan-review warnings. Current
inputs cannot enforce history-sensitive restrictions. The module adds no replacement trigger,
state rewrite, storage migration, elevated identity or recovery workaround. Architecture
acceptance may precede module tests; Developer acceptance requires both contract tests and
exact-provider evidence, including explicit-domain create/update/read and retained
counterexamples.

## References

- [Evidence requirements](../../CONTRIBUTING.md#component-evidence-requirements)
- [Provider evidence](../compatibility.md#provider-lifecycle-evidence)
- [PR #107 exact-build plan report and three Architecture findings](https://github.com/mlznlv/proxmox-iac-toolkit/pull/107#provider-level-lifecycle-evidence)
- [Provider shrink replacement intent](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L1182-L1228); [Provider shrink refusal, growth, and mount-option-only reboot flag](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3662-L3710); [Provider creation-versus-update feature encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L2540-L2602); [Provider DNS-domain schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L543-L548); [Provider DNS-domain create request](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L2228-L2234); [Provider DNS-domain read-back](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L2940-L2946); [Provider DNS-domain update/delete and reboot request](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3832-L3851); [Provider zero-swap default](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L75); [`bpg/proxmox` v0.111.1 container `unmanaged` operating-system default](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L91); [`bpg/proxmox` v0.111.1 container bootstrap account replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L642-L676); [`bpg/proxmox` v0.111.1 container template replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L993-L1006); [`bpg/proxmox` v0.111.1 container hostname must be a valid DNS name](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L569-L575); [`bpg/proxmox` v0.111.1 container memory change requires a reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3867-L3886); [`bpg/proxmox` v0.111.1 container CPU change without a reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3603-L3633); [`bpg/proxmox` v0.111.1 container features change without a reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3728-L3735); [`bpg/proxmox` v0.111.1 container root-filesystem datastore replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L408-L414); [`bpg/proxmox` v0.111.1 container unprivileged default and replacement](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L1152-L1158); [`bpg/proxmox` v0.111.1 container DNS, hostname, and network updates requiring reboot](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3832-L4051); [`bpg/proxmox` v0.111.1 container reboot after update](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L4162-L4174); [`bpg/proxmox` v0.111.1 container destroy with forced stop](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L4204-L4236); [`bpg/proxmox` v0.111.1 container `start_on_boot` default](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L98); [`bpg/proxmox` v0.111.1 container `start_on_boot` schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L1072-L1078); [`bpg/proxmox` v0.111.1 container create request sends `start_on_boot`](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L2180-L2207); [`bpg/proxmox` v0.111.1 container read waits for network interfaces](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L3477-L3509); [`bpg/proxmox` v0.111.1 omitted wait-for-IP block selects waiting for any address](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/container/container.go#L4259-L4283)
- [SDK v2.40.1 nested-block diff behavior](https://github.com/hashicorp/terraform-plugin-sdk/blob/e6c7dc42a51abcaf5b709a98720ba13ba0082021/helper/schema/schema.go#L1392-L1441)
- [Provider feature serialization](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/containers/containers_types.go#L323-L369)
- [Proxmox feature and DNS authorization](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC.pm#L1678-L1757)
- [Proxmox independent nameserver and search-domain fallback](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L33-L59); [Proxmox container create applies keys, network, hostname, and DNS through the setup plugin](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L718-L736); [Proxmox container DNS host fallback](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L33-L54); [Proxmox container systemd nesting warning](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Base.pm#L662-L679)
- [Proxmox DNS-name validation](https://github.com/proxmox/pve-common/blob/f2c4fca5c554d0ecf5f795384279b2d7ecb52a4a/src/PVE/JSONSchema.pm#L673-L683)
- [`bpg/proxmox` v0.111.1 container network-interface wait behaviour](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/containers/containers.go#L174-L218)
- [Proxmox `unmanaged` setup plugin no-ops](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC/Setup/Unmanaged.pm#L19-L85)
- [Proxmox unprivileged create default and privileged-create permission](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/API2/LXC.pm#L272-L273)
