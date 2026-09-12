# Repository design

## Durable areas

| Area | Ownership |
| --- | --- |
| `README.md` | Public landing page, scope, maturity, and navigation |
| `CHANGELOG.md` | Notable consumer-facing change history and concise migration actions |
| `docs/` | Durable project, architecture, contributor, and user documentation |
| `docs/roadmap.md` | Approved milestone-level plan |
| `docs/architecture.md` | Cross-cutting architecture and boundaries |
| `docs/repository-design.md` | Repository structure and ownership |
| `docs/compatibility.md` | Public compatibility targets, evidence levels, and non-claims |
| `docs/release-policy.md` | Release identity, maturity, publication gates, evidence, and correction policy |
| `docs/decisions/` | Architecture Decision Records |
| `.devcontainer/` | Canonical reproducible contributor environment |
| `.github/` | GitHub workflows, dependency automation, and contribution templates |
| `Taskfile.yml` | Transparent developer workflow entry point |
| `scripts/` | Small portable repository helpers when direct commands are insufficient |
| Root tool configuration and version declarations | Conventional, discoverable repository-wide tooling configuration |
| `tofu/` | Reusable OpenTofu modules and their component-local documentation and tests |
| `ansible/` | Reusable Ansible roles and their component-local documentation and tests |
| `examples/` | Cross-component consumer examples |
| `.claude/` | Optional Claude Code assistance and defense-in-depth controls |

Areas described for deferred use need not be created until they contain approved content.

## Documentation

Architecture documents and ADRs live under `docs/` and are reachable from the root README or a documentation index. Architecture, roadmap, and ADR content must not be duplicated in tool-specific guidance.

ADRs use `docs/decisions/NNNN-title.md`. Their index is `docs/decisions/README.md`.

Release documentation keeps three sources of truth distinct:

- `CHANGELOG.md` records what changed, breaking or removed behavior, and concise migration actions;
- `docs/compatibility.md` at a release commit records that release's compatibility snapshot and evidence level; and
- executable source-controlled declarations own machine-consumable provider, dependency, runtime, and tool constraints.

`docs/release-policy.md` owns durable release rules and publication gates. It references rather than restates exact Task targets, CI jobs, validation commands, tool versions, or detailed validation configuration. Those implementation details remain authoritative in their existing repository tooling, validation documentation, and CI sources.

## OpenTofu and Ansible

OpenTofu components belong under `tofu/`. Ansible components belong under `ansible/`.

The first reusable slice has exactly these approved component roots:

- `tofu/modules/proxmox-linux-vm/` for the single full-clone Linux VM module;
- `ansible/roles/qemu_guest_agent/` for the independently usable guest-agent role.

Implementation of the first M6 expansion belongs in the existing `tofu/modules/proxmox-linux-vm/` root as an optional access-VLAN input for its existing single network attachment. It creates no new module, provider resource family, Ansible role, example, shared layer, or orchestration entry point. The exact input syntax, fictional usage example, consumer prerequisites, and connectivity-disruption warning belong in that module's co-located README when the capability is implemented.

Component documentation and contract tests are co-located with their owning component. A small test fixture may demonstrate required connection-descriptor composition, but it must not become a consumer example, read real state, or couple the Ansible role to OpenTofu.

Additional module, role, collection, shared-library, or platform hierarchies remain deferred until approved content requires them.

## Examples

Examples are introduced only with supported behavior:

- component-specific examples are co-located with their owning component;
- cross-component consumer examples belong under `examples/`;
- all examples use fictional or standards-reserved values;
- examples must not depend on unpublished files or private repositories.

`examples/separate-consumer-repository/` is the one cross-component example, and it represents a separate consumer repository consuming both first-slice components from a single pinned checkout. Its directory name and internal layout are documentation conventions rather than public toolkit interfaces, and what it must contain is asserted by its own contract check rather than restated here.

An example is copyable and statically valid, but not deployment-ready, and it must not use invalid HCL or YAML placeholder tokens to communicate consumer ownership. It declares no backend and contains no provider endpoint, credential, secret, private inventory, real infrastructure value, or private-repository assumption.

An example owns no toolkit-acquisition or update automation, generated inventory, automatic OpenTofu-output wiring, state-reading automation, Taskfile orchestration, secret loading or decryption, or unattended apply behavior. Validation may represent a shared checkout with a credential-free fixture; an example does not own a submodule, vendoring, or other acquisition mechanism merely to support CI.

## Releases

The initial release structure is deliberately small: a root changelog, durable release policy, an immutable Git tag, and a GitHub Release containing only GitHub-provided source archives. `v0.1.0-alpha.1` is the only concrete first-release identifier. No package, container, or other registry hierarchy and no custom release-artifact directory is introduced for M5.

The GitHub Release is the discoverable version record and states the exact full source SHA. It summarizes and links to the changelog entry and compatibility document at that released snapshot. It does not replace those committed sources or the consumer's source-controlled full-SHA checkout declaration.

Release preparation and publication evidence belong to the PO-selected durable M5 completion record. That record identifies the candidate SHA, validation and safety evidence, and final release URL without pre-deciding the implementation-ticket boundaries. Concrete validation commands and CI jobs stay in their existing owning files rather than being copied into the record or release policy as a second implementation specification.

Publication remains an explicit maintainer operation outside normal public CI. Repository settings may enforce release immutability, but the first release requires no release workflow, privileged CI trigger, credential broker, custom signing system, registry, or artifact pipeline.

## Repository tooling

The Dev Container defines the canonical development environment, not the authoritative tool-version policy. Source-controlled version declarations and dependency locks are authoritative and must be consumable by the container, native development path, and CI as applicable.

Task provides thin, readable wrappers around documented commands. Small shared helpers may live under `scripts/`, but scripts must not become a hidden workflow engine or own infrastructure state.

Tool-specific configuration such as `.claude/` is optional and non-authoritative.

## Structure still not permitted

The first slice and initial consumer workflow must not create:

- speculative additional module, role, service, platform, or environment hierarchies;
- private inventories or deployment roots;
- real backend, provider, endpoint, topology, or sizing configuration;
- generated state or sensitive plans in public source or artifacts;
- real secrets, age identities, or private keys in public source or artifacts;
- mandatory dotfiles integration;
- live-test infrastructure;
- toolkit-owned acquisition or synchronization of a consumer checkout;
- generated inventory, cross-component state reading, or automatic Task wiring;
- custom release artifacts, registry publication, or automated release infrastructure;
- additional virtualization-platform abstractions.
