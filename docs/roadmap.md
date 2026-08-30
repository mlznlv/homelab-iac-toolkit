# Project roadmap

## Current state

- **Current phase:** M1 — Architecture and roadmap baseline
- **Implementation state:** No Developer work item is Ready.
- **Current blocker:** Foundational architecture baseline.
**Next action:** Architecture defines and commits the foundational architecture baseline.

The repository already includes its public project contract, license, public-safety rules, editor defaults, contribution templates, dependency automation, CI and validation foundations, and shared Claude Code configuration. These artifacts must be reviewed and reconciled with accepted Architecture where they depend on decisions not yet recorded.

## Milestone sequence

1. M1 — Architecture and roadmap baseline
2. M2 — Reproducible development foundation
3. M3 — First reusable toolkit slice
4. M4 — Consumer-ready toolkit
5. M5 — First pre-release

## M1 — Architecture and roadmap baseline

**Goal:** Provide the durable decisions and approved plan required for implementation.

**Why:** Existing foundations and future public interfaces need authoritative architecture.

**Entry criteria:**

- Public project contract is approved.
- Current repository state is inventoried.

**Exit criteria:**

- Architecture overview and repository design are committed.
- Required foundational ADRs are accepted.
- Existing foundation work is reconciled with Architecture.
- The first Developer-executable work item can be selected without architectural guesswork.

**Architecture dependencies:** Repository structure and boundaries; high-level lifecycle ownership; tool and version policy; developer-environment model; validation and CI boundaries; ADR convention; public/private interface boundaries.

**Major deliverables:** Architecture overview, repository design, foundational ADRs and this approved roadmap.

**Risks / blockers:** Existing implementation may encode decisions that Architecture has not approved and may require adjustment.

**Deferred work:** Reusable toolkit components, consumer examples and releases.

## M2 — Reproducible development foundation

**Goal:** Make toolkit development and validation reproducible for contributors and maintainers.

**Why:** Component work needs an approved repository structure, repeatable tooling and consistent local and CI validation.

**Entry criteria:** M1 architecture is accepted and existing foundation artifacts have been assessed against it.

**Exit criteria:**

- Repository structure matches the approved design.
- A reproducible developer environment is available and documented.
- Local validation is documented and repeatable.
- Local validation and CI enforce equivalent expectations.
- Task entry points exist if approved as the workflow interface.
- Existing CI, Dependabot, templates and validation configuration are aligned with Architecture.
- Contributor, security and documentation-navigation foundations exist.

**Architecture dependencies:** Repository structure; developer-environment model; tool/version policy; local credential-handling boundaries; workflow interface; CI and testing strategy; contributor and security-documentation requirements.

**Major deliverables:** Aligned repository structure, reproducible developer environment, local validation workflow, local/CI parity and contributor documentation.

**Risks / blockers:** Existing validation may require revision. Developer tooling must not embed private credentials or personal configuration.

**Deferred work:** Live Proxmox testing, infrastructure apply and validation for components that do not yet exist.

## M3 — First reusable toolkit slice

**Goal:** Deliver the smallest architecture-approved reusable slice that provides real consumer value.

**Why:** The project becomes useful when a separate repository can consume a validated public capability.

**Entry criteria:** M2 is complete, Architecture has selected the first slice and its required platform and validation decisions exist.

**Exit criteria:**

- The approved slice is implemented and validated.
- A separate consumer can use it without private toolkit dependencies.
- Its public interface, limitations and maturity are documented.
- Public validation requires no private deployment access.
- Destructive or lifecycle-sensitive behavior is documented where applicable.

**Architecture dependencies:** Selection and boundaries of the first slice; relevant provider, module, role or coordinated-slice decisions; supported-platform policy; public-interface rules; testing and evidence requirements.

**Major deliverables:** First reusable toolkit slice, component documentation and relevant credential-free validation.

**Risks / blockers:** The slice may be OpenTofu-first, Ansible-first or coordinated; roadmap planning must not choose before Architecture. Public interfaces must not encode a private homelab.

**Deferred work:** Additional components, higher-level abstractions and capabilities without demonstrated consumer value.

## M4 — Consumer-ready toolkit

**Goal:** Make the initial toolkit slice understandable and practical to consume from a separate deployment repository.

**Why:** A reusable component needs a clear consumer workflow and public-safe guidance.

**Entry criteria:** The M3 slice is approved and validated, and the initial consumer contract is defined.

**Exit criteria:**

- A public-safe consumer example exists.
- Separate-repository consumption is documented.
- Required configuration interfaces are documented.
- A configuration/secrets interface is included where required by the approved consumer design.
- SOPS/age integration is documented if needed by that design.
- Getting Started and troubleshooting guidance exist.
- Optional live testing, if approved, remains isolated from normal public CI.

**Architecture dependencies:** Consumer composition model; examples strategy; configuration and secrets interfaces where required; compatibility expectations; optional integration-test design.

**Major deliverables:** Consumer example, Getting Started guide, configuration guidance, applicable secrets guidance and troubleshooting documentation.

**Risks / blockers:** Examples may accidentally create undocumented interfaces. Consumer material must not contain private deployment data.

**Deferred work:** Concrete private deployment configuration, mandatory live CI and integrations unrelated to the initial consumer workflow.

## M5 — First pre-release

**Goal:** Publish an immutable, documented pre-release for early consumers.

**Why:** Consumers need a reproducible version and clear maturity expectations.

**Entry criteria:** The M4 consumer workflow is validated and release and compatibility decisions are accepted.

**Exit criteria:**

- An immutable pre-release is published.
- Consumption instructions reference an immutable version.
- Changelog and compatibility information exist.
- Upgrade and migration expectations are documented.
- The release process is documented and validated.

**Architecture dependencies:** Versioning, compatibility, changelog, migration expectations and release process.

**Major deliverables:** First pre-release, changelog, compatibility statement, upgrade guidance and release documentation.

**Risks / blockers:** A release may create unsupported compatibility expectations and must match the approved architecture.

**Deferred work:** Stable 1.0 commitment, registry publication unless justified, automated deployment and broad toolkit expansion.

## Architecture prerequisites

### Foundational architecture baseline

Architecture must provide:

- approved repository structure and boundaries;
- high-level lifecycle ownership;
- developer-environment and tool-version policies;
- local workflow, validation and CI boundaries;
- public/private interface rules;
- ADR structure and decision-recording convention;
- assessment of existing CI and safety foundations against those decisions.

This is Architecture-owned and is not a Developer implementation ticket.

### Later prerequisites

- **First slice:** its scope, public boundary and relevant provider, platform, validation and evidence requirements.
- **Consumer:** consumption model, examples contract, required configuration/secrets interfaces and optional live-test needs.
- **Release:** versioning, compatibility, changelog, migration and release decisions.

## Near-term Developer work

All near-term Developer work is blocked by the foundational architecture baseline.

### DEV-001 — Reconcile the existing repository foundation

- **Milestone:** M2
- **Status:** Blocked

Align existing CI, validation configuration, templates, dependency automation, safety controls and repository layout with accepted Architecture. Do not rebuild working foundations without an approved reason.

### DEV-002 — Add the reproducible developer environment

- **Milestone:** M2
- **Status:** Blocked

Implement and document the approved developer environment after Architecture defines its model, tool versions, contents and credential boundaries.

### DEV-003 — Align local validation with public CI

- **Milestone:** M2
- **Status:** Blocked

Provide repeatable local checks equivalent to approved public CI expectations. Add Task entry points only if approved. Live infrastructure, private credentials and infrastructure apply remain out of scope.

## Deferred work

- Additional modules and roles beyond the first validated slice.
- Generic dotfiles integration.
- Live Proxmox testing outside an approved isolated path.
- Stable 1.0 compatibility commitment.
- Automated infrastructure apply.
- Concrete private deployment configuration.
- Registry publication.
- Higher-level composition abstractions.
- Additional providers or virtualization platforms.
