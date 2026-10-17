# Architecture

## Repository boundary

The toolkit owns reusable source, interfaces, sanitized examples, documentation, validation and
contributor tooling. It must work without an unpublished file or private deployment repository.
Consumers own environment composition, inventory, provider/backend configuration, state custody,
credentials, identities, topology, sizing and workload policy. [Security](../SECURITY.md) owns
publication rules.

## Lifecycle ownership

| Concern | Owner |
| --- | --- |
| Proxmox resources and infrastructure dependencies | OpenTofu |
| Continuing guest OS, users, packages and services | Ansible |
| Transparent developer workflow orchestration | Task |
| Encryption interface for committed secrets | SOPS and age |
| Durable source, configuration, documentation and decisions | Git |
| Public validation | Repository tooling and GitHub Actions |

Each concern has one lifecycle owner. OpenTofu may bootstrap initial access; Ansible must not
create or destroy Proxmox resources. Scripts and CI invoke owners without maintaining competing
state, hidden recovery or configuration. See [ADR
0002](decisions/0002-lifecycle-orchestration-ownership.md).

## Dependency direction

Consumer configuration depends on reusable components. Components do not depend on examples,
private files, each other, or tool-specific assistant configuration. The VM and LXC modules are
siblings with separate interfaces; the guest-agent role takes ordinary inventory and reads no
OpenTofu state. Current interfaces, lifecycle rules and limits belong to their READMEs, linked
from the root index.

[Using the toolkit](using.md) owns the coordinated checkout and manual handoff workflow. Task
does not acquire toolkit revisions, generate inventory, wire outputs, load credentials, or
automate deployment. Public examples must parse with fictional values and explicit input
boundaries; they declare no backend or provider endpoint and add no acquisition, state-reading
or secret mechanism.

## Repository layout

| Area | Responsibility |
| --- | --- |
| `tofu/modules/<name>/` | Module source, interface README and contract tests |
| `ansible/roles/<name>/` | Role source, interface README and contract tests |
| `examples/<name>/` | Supported cross-component examples and their checks |
| `docs/decisions/` | Durable decision rationale |
| `.devcontainer/` | Canonical contributor environment |
| `.github/` | CI, dependency automation and contribution templates |
| `scripts/` | Small portable helpers when direct commands are insufficient |
| Root declarations/configuration | Shared tool versions, locks and validation |
| `.claude/` | Optional, non-authoritative agent assistance |

Component examples stay beside their component; cross-component examples live under `examples/`.
Add hierarchies only for approved content. No speculative platform, distribution, service,
environment or shared abstraction is implied.
[Contributing](../CONTRIBUTING.md#documentation-ownership) owns document placement.

## Contributor control plane

The Dev Container, native setup and CI consume the same executable declarations.
[Contributing](../CONTRIBUTING.md) owns setup and evidence procedures;
[Taskfile.yml](../Taskfile.yml) owns discoverable, direct commands. Task uses no cached
validation result. Optional assistant configuration must be removable without losing correctness
or usability and must link to public authority.

## Validation boundary

Normal local and public CI validation is deterministic, non-destructive and credential-free,
with the same checks, versions, configuration and pass/fail semantics. Public network access
serves dependency acquisition and link checks; private networks, repositories and deployment
infrastructure are excluded.

CI treats PR code as untrusted, uses minimal token permissions, persists no credentials unless
an approved workflow needs them, pins third-party actions immutably and verifies downloaded
executables/dependencies. Privileged PR triggers must not execute untrusted code. No sensitive
state, plans, logs or decrypted artifacts may be published. [ADR
0004](decisions/0004-local-validation-task-ci-security-boundary.md) records these decisions;
[Compatibility](compatibility.md) owns evidence claims.

Live testing requires separate accepted Architecture, isolation from normal CI, explicit opt-in
and defined credential custody, trusted triggers, infrastructure ownership, cleanup, failures
and cost responsibility before implementation. [Proposal #127](https://github.com/mlznlv/proxmox-iac-toolkit/pull/127) does not itself authorize a live
run.

## Extension boundaries

[ADR 0017](decisions/0017-guest-distribution-extension-and-qualification.md) governs separate
VM-template, LXC and per-role qualification. Support is not transitive between tracks or to
their composition. An unchanged suitable VM template is a consumer choice; naming a target is a
claim; changing bootstrap is a capability decision. Debian LXC has no distribution extension
point. Another target needs its own decision, including placement; no OS selector or
distribution layer is introduced.
[Compatibility](compatibility.md#guest-distribution-qualification) owns qualification evidence
and requalification.
