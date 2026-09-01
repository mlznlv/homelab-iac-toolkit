# Repository design

## Durable areas

| Area | Ownership |
| --- | --- |
| `README.md` | Public landing page, scope, maturity, and navigation |
| `docs/` | Durable project, architecture, contributor, and user documentation |
| `docs/roadmap.md` | Approved milestone-level plan |
| `docs/architecture.md` | Cross-cutting architecture and boundaries |
| `docs/repository-design.md` | Repository structure and ownership |
| `docs/compatibility.md` | Public compatibility targets, evidence levels, and non-claims |
| `docs/decisions/` | Architecture Decision Records |
| `.devcontainer/` | Canonical reproducible contributor environment when implemented |
| `.github/` | GitHub workflows, dependency automation, and contribution templates |
| `Taskfile.yml` | Transparent developer workflow entry point when implemented |
| `scripts/` | Small portable repository helpers when direct commands are insufficient |
| Root tool configuration and version declarations | Conventional, discoverable repository-wide tooling configuration |
| `tofu/` | Reusable OpenTofu modules and their component-local documentation and tests |
| `ansible/` | Reusable Ansible roles and their component-local documentation and tests |
| `examples/` | Future cross-component consumer examples |
| `.claude/` | Optional Claude Code assistance and defense-in-depth controls |

Areas described for deferred use need not be created until they contain approved content.

## Documentation

Architecture documents and ADRs live under `docs/` and are reachable from the root README or a documentation index. Architecture, roadmap, and ADR content must not be duplicated in tool-specific guidance.

ADRs use `docs/decisions/NNNN-title.md`. Their index is `docs/decisions/README.md`.

## OpenTofu and Ansible

OpenTofu components belong under `tofu/`. Ansible components belong under `ansible/`.

The first reusable slice has exactly these approved component roots:

- `tofu/modules/proxmox-linux-vm/` for the single full-clone Linux VM module;
- `ansible/roles/qemu_guest_agent/` for the independently usable guest-agent role.

Component documentation and contract tests are co-located with their owning component. A small test fixture may demonstrate optional connection-value composition, but it must not become a consumer example, read real state, or couple the Ansible role to OpenTofu.

Additional module, role, collection, shared-library, or platform hierarchies remain deferred until approved content requires them.

## Examples

Examples are introduced only with supported behavior:

- component-specific examples are co-located with their owning component;
- cross-component consumer examples belong under `examples/`;
- all examples use fictional or standards-reserved values;
- examples must not depend on unpublished files or private repositories.

## Repository tooling

The Dev Container defines the canonical development environment, not the authoritative tool-version policy. Source-controlled version declarations and dependency locks are authoritative and must be consumable by the container, native development path, and CI as applicable.

Task provides thin, readable wrappers around documented commands. Small shared helpers may live under `scripts/`, but scripts must not become a hidden workflow engine or own infrastructure state.

Tool-specific configuration such as `.claude/` is optional and non-authoritative.

## Structure still not permitted

The first slice must not create:

- speculative additional module, role, service, platform, or environment hierarchies;
- private inventories or deployment roots;
- real backend, provider, endpoint, topology, or sizing configuration;
- generated state or sensitive plans in public source or artifacts;
- real secrets, age identities, or private keys in public source or artifacts;
- mandatory dotfiles integration;
- live-test infrastructure;
- release or registry structure;
- additional virtualization-platform abstractions.

## Existing-foundation reconciliation

| Existing item | Classification | Assessment |
| --- | --- | --- |
| `README.md` and `docs/roadmap.md` | RETAIN | They provide the approved public contract, navigation, phase, and M1/M2 boundary. |
| Current minimal repository layout | RETAIN | It avoids speculative component structure. Add only approved documentation and later M2 tooling. |
| Existing CI | RECONCILE | Retain credential-free events, minimal permissions, immutable action references, and security checks. Align CI with shared local validation and executable-integrity policy. The current runner label alone is not a reason to change runner policy. |
| Validation configuration | RETAIN | Markdown and YAML configuration is focused and suitable for the current repository. Expose equivalent checks locally during M2. |
| Dependabot | RETAIN | GitHub Actions updates support immutable-reference maintenance. Extend only when another managed ecosystem exists. |
| GitHub templates | RECONCILE | Preserve the approved Developer workflow while allowing Architecture-owned changes to cite their roadmap or architecture authority without inventing an implementation specification. |
| `.gitignore` | RECONCILE | Its direction is correct. Align key and plaintext-secret patterns with the public-safety policy without hiding legitimate reusable source. |
| `.editorconfig` | RETAIN | The portable formatting defaults are sufficient. |
| `CLAUDE.md` | RECONCILE | Its public/private guidance aligns, but current-state text and references must follow accepted repository documentation. |
| `.claude/settings.json` and other `.claude/` controls | RECONCILE | These files exist and are useful defense in depth. Keep them optional, align them with accepted commands and safety policy, and do not treat them as enforcement for non-Claude workflows. |
| License | RETAIN | Apache 2.0 is consistent with the public project contract. |
| Repository settings | DEFER | Rulesets, merge methods, required checks, and wiki configuration may be reviewed through the approved workflow. No current setting is an M2 architecture blocker without a concrete reproducibility, security, or source-of-truth conflict. |

No existing foundation item requires replacement.
