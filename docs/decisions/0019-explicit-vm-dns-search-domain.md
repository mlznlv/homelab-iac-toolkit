# ADR 0019: Require an explicit consumer-owned VM DNS search domain

## Status

Accepted

## Context

The VM module declares DNS servers but no search domain. The [VM-specific investigation for #121](https://github.com/mlznlv/proxmox-iac-toolkit/issues/121#issuecomment-6233199488) inspected locked `bpg/proxmox` v0.111.1 at source `b22fe919fc34476b232191b69c8907f0c1aa5bea` and Proxmox qemu-server at `14c0f871fa926e04eee090afae5d2d8670aa4a79`.

The clone path copies a template's configured search domain. With no explicit VM domain, Proxmox's cloud-init generator independently falls back to the selected node's search domain, even when nameservers are declared. Required nameservers therefore do not make all DNS bootstrap configuration consumer-explicit.

The provider sends a nonempty domain during clone initialization and update, and reads it back. An empty domain is instead omitted; the VM update path does not delete an existing `searchdomain`. Its read-back can consequently restore a value the configuration attempted to remove. This differs from the LXC deletion path and does not establish a supported clearing transition.

An explicit domain also affects generated user data: Proxmox appends it to the module's single-label VM name to form the FQDN. The upstream helper's qualified-name branch does not expand this module's existing name interface. Initialization changes request cloud-init rebuild and reboot on the pinned provider, and changed generated user/network data changes the NoCloud instance identifier.

These are VM-specific source findings, not an extension of [ADR 0015](0015-first-lxc-lifecycle-and-dns-contract.md). The investigation executed only extracted DNS/hostname helper functions with a fictional resolver reader; it did not run full Proxmox/cloud-init or a guest. No live lifecycle, DNS or connectivity evidence is claimed.

## Decision

Require one explicit, nonempty, consumer-supplied VM DNS search domain alongside the existing required DNS servers. There is no toolkit default, node/template-derived value, domain-list interface or no-search sentinel. The module passes the validated declaration through the existing provider DNS initialization field. Locally decidable invalid domain/name combinations fail before apply; validating the domain alone must not permit an overlong generated FQDN or widen the existing single-label VM-name contract.

This refines the previously incomplete VM DNS ownership boundary without changing the resource family or the other decisions in [ADR 0006](0006-guest-agent-channel-at-creation.md), [ADR 0012](0012-dhcp-primary-attachment-addressing.md), [ADR 0013](0013-static-ipv6-primary-attachment.md) or [ADR 0014](0014-additional-attachment-retirement-lifecycle.md). It preserves [public/private boundaries](0001-public-toolkit-private-deployment-boundary.md), [lifecycle ownership](0002-lifecycle-orchestration-ownership.md) and [credential-free validation](0004-local-validation-task-ci-security-boundary.md).

OpenTofu owns the declared Proxmox cloud-init search-domain setting. Consumers own its value, namespace, DNS service, template suitability and consistency with the VM name and their environment. Continuing guest resolver configuration remains an Ansible/consumer concern; no role or alternative configuration mechanism is introduced.

Initial explicit declaration, adoption on an existing VM, and a change from one valid nonempty domain to another must preserve the VM and converge at provider update/read level. Removal, empty values and a return to inheritance are not supported. The implementation evidence gate must cover each supported transition, including replacement of a template-inherited value and a subsequent no-change plan grounded in the exact provider's update/read paths.

An in-place plan alone does not establish convergence or successful guest DNS. Domain changes carry the established initialization rebuild/reboot and new-instance consequences, including a changed generated FQDN where applicable, possible SSH host-key regeneration and interrupted connectivity. Provider upgrades must re-evaluate this behavior rather than silently permit replacement or non-convergence.

The exact input and validation contract belongs in [Architecture](../architecture.md#vm-dns-search-domain). Evidence and non-claims belong in [Compatibility](../compatibility.md#vm-dns-search-domain). Component syntax/examples and required caller updates are Developer work after acceptance, not implementation in this decision.

## Consequences

- This is a breaking required-input addition. Existing consumers must deliberately choose a domain before adopting the implementation; even retaining an inherited value is an explicit consumer choice, not automatic discovery.
- Consumers review the plan and bootstrap/disruption consequences before explicit apply. The toolkit does not rewrite configuration, mutate state, clear Proxmox fields directly, or migrate consumers automatically.
- The primary IPv4 modes, static IPv6, additional-attachment lifecycle, required DNS servers and metadata-only `connection` contract stay unchanged. The domain is global DNS initialization, not per-attachment addressing.
- An explicit no-search mode remains deferred: an accepted API string is not evidence of reliable no-search semantics across generated user/network data and guest renderers.
- Architecture acceptance rests on pinned source evidence and explicit limits; Developer acceptance separately requires module tests, exact-provider implementation evidence, the consumption-minimum evidence of [ADR 0016](0016-module-cli-minimum-and-evidence-policy.md) and reconciled existing documentation/callers.
- No provider/CLI upgrade, PVE target change, LXC change, new Ansible capability, live-testing requirement or orchestration is introduced.

## Alternatives considered

- **Optional domain with inherited defaults:** rejected for this contract. It retains environment-specific behavior and cannot offer a truthful generic set-then-remove transition on the pinned provider.
- **Document inheritance and defer an input:** rejected for the selected increment; it leaves the demonstrated ownership gap unresolved.
- **Expose empty or dot-like no-search values:** deferred. Empty is omitted by the provider; the VM API's string acceptance alone does not establish a safe public no-search contract.
- **Bypass the provider to clear the domain:** rejected. It introduces competing lifecycle ownership and hidden mutation.

## Sources

- [Provider domain schema](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L865-L890)
- [Provider domain mapping and omission](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L3586-L3614)
- [Provider domain read-back](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L5039-L5059)
- [Provider request encoding](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmox/nodes/vms/custom_cloud_init.go#L105-L121)
- [Provider initialization update/rebuild/reboot path](https://github.com/bpg/terraform-provider-proxmox/blob/b22fe919fc34476b232191b69c8907f0c1aa5bea/proxmoxtf/resource/vm/vm.go#L6592-L6684)
- [Proxmox clone configuration inheritance](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/API2/Qemu.pm#L4510-L4580)
- [Proxmox VM FQDN and independent DNS fallback](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L112-L143)
- [Proxmox NoCloud instance identity](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer/Cloudinit.pm#L604-L623)
