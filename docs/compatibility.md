# Compatibility

This page owns targets and evidence. At a release commit it is that release's snapshot; `main`
can include unreleased changes. Executable `versions.tf` files own module CLI/provider
constraints; contributor versions belong to [the declarations](../CONTRIBUTING.md#set-up).
[Release policy](release-policy.md#maturity) owns maturity and support commitments.

## Support and evidence matrix

| Surface | Target | Evidence and limit |
| --- | --- | --- |
| [VM](../tofu/modules/proxmox-linux-vm/README.md) | Proxmox VE 9.x; consumer cloud-init template meeting its README contract | Static/mocked declarations and exact-provider lifecycle evidence; no distribution-specific VM template qualification |
| [LXC](../tofu/modules/proxmox-linux-container/README.md) | Proxmox VE 9.x; Debian Stable template meeting its README contract | Expected-compatible; mocked declarations, provider plans and pinned setup source |
| [Guest-agent role](../ansible/roles/qemu_guest_agent/README.md) | Debian Stable and Kali Rolling meeting its capability contract | Expected-compatible; syntax/lint/static role checks and packaging inspection |
| [Consumer example](../examples/separate-consumer-repository/README.md) | One pinned checkout for VM and role | Structural resolution and inventory mapping only; adds no platform target |
| Live integration | None recorded | No runtime-validated reference platform |

Existing release-series targets retain their prior wording/evidence until their next
requalification trigger; they do not cover an unevaluated release. Other Debian-family guests
may meet a role contract without gaining a toolkit claim. The supported PVE major does not
float: adopting another requires deliberate compatibility review, validation and declaration
updates; a changed durable policy requires an ADR.

## OpenTofu CLI compatibility and evidence

[ADR 0016](decisions/0016-module-cli-minimum-and-evidence-policy.md) retains 1.6.0 as the
intended consumer minimum for both modules. **Current VM source breaches that target.** At
unmodified source `3a8553a16bcfd5a4e78957988d96f0b5fc9ab543`, consuming-root initialization
succeeded on the sampled CLIs; nullable-default validation produced:

| CLI | VM | LXC |
| --- | --- | --- |
| 1.6.0, 1.9.4 | Failed identifier/VLAN guards | Passed baseline |
| 1.10.0, 1.12.6 | Passed baseline | Passed baseline |

These are sampled init/validate results, not full-feature or interval-wide qualification.
[Investigation](https://github.com/mlznlv/proxmox-iac-toolkit/issues/120#issuecomment-6233199326)
and [correction #112](https://github.com/mlznlv/proxmox-iac-toolkit/issues/112) track evidence;
the minimum requires fresh final-source checks under
[Contributing](../CONTRIBUTING.md#module-consumption-compatibility-evidence). Contributor-pin
mock tests do not establish the minimum. Provider signing remains separate in
[#111](https://github.com/mlznlv/proxmox-iac-toolkit/issues/111); a CLI warning difference does
not resolve signing.

## Provider lifecycle evidence

The reviewed build is `bpg/proxmox` v0.111.1, source `b22fe919fc34476b232191b69c8907f0c1aa5bea`.
Repository locks pin validation; consumers select their own root locks. A merely allowed build
acquires no evidence. The component READMEs own supported transitions and disruption/destruction
rules.

| Capability | Evidence source | What was established |
| --- | --- | --- |
| Agent channel | [ADR 0006](decisions/0006-guest-agent-channel-at-creation.md) | Pinned Proxmox/packaging/provider source; channel/wait separation |
| VLAN | [ADR 0009](decisions/0009-first-m6-vlan-expansion.md), VM README history | Schema/source and refresh-disabled exact-build plans for add/change/remove |
| Additional attachments | [PR #102](https://github.com/mlznlv/proxmox-iac-toolkit/pull/102), [ADR 0014](decisions/0014-additional-attachment-retirement-lifecycle.md) | Synthetic-state plans, source-grounded modeled read-back, supported updates and retained-entry counterexamples |
| DHCP/primary MAC | [PR #114](https://github.com/mlznlv/proxmox-iac-toolkit/pull/114), [ADR 0012](decisions/0012-dhcp-primary-attachment-addressing.md) | Mode/MAC mapping, in-place plans and modeled subsequent no-change plans |
| Static IPv6 | [PR #113](https://github.com/mlznlv/proxmox-iac-toolkit/pull/113), [ADR 0013](decisions/0013-static-ipv6-primary-attachment.md) | Add/change/remove plans and modeled convergence across IPv4 modes; pinned cloud-init renderer source |
| LXC | [PR #107](https://github.com/mlznlv/proxmox-iac-toolkit/pull/107), [ADR 0015](decisions/0015-first-lxc-lifecycle-and-dns-contract.md) | Synthetic-state lifecycle plans plus provider/SDK/Proxmox inspection for keys, DNS, shrink, nesting, reboot and read/destroy behavior |

No apply or live refresh was executed by this evidence. Source-grounded modeled read-back is
distinct from an observed no-op after apply. Provider upgrades must re-evaluate exact-build
planning and update/read paths under the [acceptance
procedure](../CONTRIBUTING.md#component-evidence-requirements). Unexpected replacement or
recurring differences for a supported update block adoption pending Architecture review.

## Current evidence level

| Class | Proves | Does not prove |
| --- | --- | --- |
| Static/mocked | Declared inputs, validation, provider fields, outputs, role tasks and example composition | Provider lifecycle, authorization or a running guest |
| Exact-provider | Executed plans at recorded CLI/build/source; inspected update/read behavior | Actual apply, refresh, hot-plug, MAC continuity or guest convergence |
| Pinned guest source | Packaging, cloud-init and setup-plugin expectations at inspected versions | Template behavior observed on a guest |
| Guest runtime | Only recorded scenarios at exact recorded identities | Other versions/environments or untested operations; none exists here |

No public check establishes live provisioning, clone/start/update/destroy,
shutdown/reboot/backup, cloud-init, host-key behavior, SSH/privilege escalation, agent
operation, Ansible convergence/idempotency, VLAN/routing, DHCP lease or naming, IPv6/RA, LXC
setup/nesting/DNS, checkout acquisition or a consumer's connectivity. Static/mocked evidence
must never be called runtime validation.

## Guest-distribution qualification

[ADR 0017](decisions/0017-guest-distribution-extension-and-qualification.md) owns why tracks and
expansion gates are separate. **Not targeted** is the default; **expected-compatible** requires
applicable static/mocked, exact-provider and pinned guest-source evidence; **runtime-validated**
requires recorded guest execution through an accepted isolated live path. Consumer runs may
demonstrate need but are not toolkit runtime evidence. Support does not transfer between VM
templates, LXC, individual roles or their composition.

| Track | Required qualification inputs |
| --- | --- |
| VM | Template provenance; cloud-init version/datasource/format/renderer and covered capabilities; default-user privilege; first-boot/package upgrades; new-instance/network/host-key effects; agent packaging when paired with a role. Provider evidence is refreshed when module/provider changes. |
| LXC | Type/detected distribution agreement, pinned setup plugin and release limits; creation/every-start network/hostname/DNS/root-key behavior; unprivileged init/nesting and root SSH template contract; provider create/type-read/template-and-type lifecycle evidence. |
| Each role | Python, package manager/name, service manager/unit/activation, non-interactive privilege, inventory/connection and device requirements; runtime claims require convergence and a no-change second run. |

Each sanitized record identifies component/track, distribution/architecture, exact release
(dated image/snapshot for rolling releases), public template/image identity and published
checksum, PVE major/relevant packages, provider build/source, OpenTofu, Ansible, cloud-init,
init-system and Python versions as applicable, toolkit commit, evidence classes, executed versus
inspected work, failures and counterexamples. Never use a private volume/storage path as image
identity.

Requalify affected tracks before retaining claims when release/series or end of life changes; an
image rebuild changes cloud-init/init/packages/units/SSH defaults; PVE major/relevant package or
provider changes; Ansible changes Python/module support; the component contract changes; or a
credible counterexample appears. Retained claims need an Architecture-reviewed record update.
Narrowing/withdrawal also needs changelog and migration guidance; existing guests are not
converted.
