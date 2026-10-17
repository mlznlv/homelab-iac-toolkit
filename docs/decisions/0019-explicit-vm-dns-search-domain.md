# ADR 0019: Explicit consumer-owned VM DNS search domain

Status: Accepted in [PR #128](https://github.com/mlznlv/proxmox-iac-toolkit/pull/128),
under [#121](https://github.com/mlznlv/proxmox-iac-toolkit/issues/121).
Implementation remains separate; this is not an existing module input.

## Decision

- Require non-null string `dns_search_domain`, no default: one ASCII DNS name with
  1–63-character letter/digit/inner-hyphen labels, maximum 253 characters, no trailing dot.
  Permit a single label; reject empty/whitespace, lists, malformed names and `.`.
- Preserve VM `name` as a single DNS label at most 63 characters; reject known `name.domain`
  combinations exceeding 253 characters before apply. Pass the domain unchanged to
  `initialization.dns.domain`, never derive it from name/template/node.
- Keep DNS servers required and all IPv4 static/DHCP, optional IPv6, attachment,
  gateway/MAC/VLAN and connection contracts unchanged. Domain is global initialization; never
  append it to connection metadata or add guest DNS/service/IPAM orchestration.
- Make domain/namespace/service/template suitability consumer-owned. OpenTofu owns its Proxmox
  declaration; ongoing guest resolver configuration stays Ansible/consumer-owned.
- Require initial declaration, adoption from node/template inheritance and nonempty changes to
  preserve the VM and converge. Removal, empty values, return to inheritance and no-search mode
  are unsupported; replacement or recurring differences block provider adoption pending
  Architecture review.
- Require independent module and exact-provider acceptance evidence below, refreshed on provider
  upgrades. This breaking input requires deliberate consumer selection and reconciled existing
  documentation/example/fixtures, without automatic migration.

## Rationale

VM clone copies an explicit template domain; absent that, cloud-init independently uses the node
search domain despite explicit nameservers. The provider sends/reads a nonempty domain but omits
empty without deleting an existing field, risking recurring differences. LXC has a different
deletion path and cannot establish VM semantics. Optional inheritance leaves ownership implicit;
bypassing the provider would create competing mutation. API string acceptance proves no safe
no-search sentinel.

Explicit domain also changes generated `name.domain` and potentially user/network data. Even
choosing the previous node fallback can change FQDN because the hostname helper does not use
that fallback. Its qualified-name branch does not widen this module's name contract.
Initialization update requests cloud-init rebuild/reboot; changed rendered data changes NoCloud
instance identity.

## Consequences

Consumers review disruptive reconfiguration, changed FQDN, possible SSH host-key regeneration
and lost connectivity; this is not cosmetic or a zero-downtime promise. The toolkit does not
rewrite configuration/state, clear Proxmox directly or migrate consumers. Explicit no-search
awaits separately reviewed semantics and convergence.

Module checks must cover required/null/empty/name/list validation, accepted/rejected
generated-FQDN boundaries, unchanged pass-through servers/addressing/connection and absence of
defaults/no-search. Exact locked-provider evidence must cover first explicit initialization,
adoption from node fallback and explicit template domain, and one nonempty change; preserve
unrelated networking/VM and show a subsequent no-change plan for each update from
source-grounded read-back. Distinguish executed plans, modeled read-back and inspected
create/update/read/rendering from live evidence.

Architecture may be accepted before finished module tests; Developer acceptance requires those
tests/evidence and consistent existing callers using fictional domains. No new
example/consumption model, provider/CLI/PVE change, LXC change, Ansible capability or
live-testing requirement is introduced. The investigation executed extracted DNS/hostname
helpers with a fictional resolver reader only: no installed Proxmox/cloud-init, apply/refresh,
guest resolver/hostname, DNS, reboot, SSH or reachability proof.

Implementation must preserve the retained CLI minimum with the consuming-root evidence of
[ADR 0016](0016-module-cli-minimum-and-evidence-policy.md). The combined name/domain rule spans
two inputs and must not rely on cross-variable validation available only in a newer CLI.

Repeated apply, ignored differences and direct Proxmox cleanup are not supported convergence
remedies for this DNS contract.

## References

- [Investigation](https://github.com/mlznlv/proxmox-iac-toolkit/issues/121#issuecomment-6233199488)
- [DNS presentation bounds](https://www.rfc-editor.org/rfc/rfc1035.html#section-2.3.4)
- [Provider domain schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L865-L890); [Provider domain mapping and omission](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L3586-L3614); [Provider domain read-back](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L5039-L5059); [Provider initialization update/rebuild/reboot path](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6592-L6684)
- [Provider request encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/vms/custom_cloud_init.go#L105-L121)
- [Proxmox clone configuration inheritance](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/API2/Qemu.pm#L4510-L4580)
- [Proxmox VM FQDN and independent DNS fallback](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L112-L143); [Proxmox NoCloud instance identity](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L604-L623)
