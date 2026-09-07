# Project roadmap

## Current state

- **Current phase:** M5 — First pre-release
- **Milestone state:** M1, M2, M3 and M4 are complete. The first pre-release contract is accepted through ADR 0008.
- **Implementation state:** M5 implementation is the current execution focus. Developer work becomes Ready only through focused Issues derived from the accepted first pre-release contract.
- **Current blocker:** None at milestone level; Issue-level dependencies determine implementation readiness.
- **Next action:** Decompose and implement the accepted source-only first pre-release through focused Developer Issues.

## Milestone sequence

1. M1 — Architecture and roadmap baseline
2. M2 — Reproducible development foundation
3. M3 — First reusable toolkit slice
4. M4 — Consumer-ready toolkit
5. M5 — First pre-release
6. M6 — Broader Proxmox infrastructure
7. M7 — Reusable guest and service configuration
8. M8 — Composition and ecosystem integration
9. M9 — Integration confidence and compatibility expansion
10. M10 — Release maturity and stable-readiness

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

## M6 — Broader Proxmox infrastructure

**Goal:** Expand reusable OpenTofu capabilities beyond the initial Linux VM slice.

**Why:** Practical Proxmox deployments need more resource and networking patterns without importing one private environment into the toolkit.

**Entry criteria:** M5 is complete, demonstrated consumer needs are identified, and Architecture has accepted the boundaries and evidence requirements for the selected expansion.

**Exit criteria:**

- Architecture-approved additional VM patterns and LXC support are reusable, documented and validated.
- Storage and disk capabilities approved for demonstrated needs document lifecycle, replacement and destructive behavior.
- Approved network capabilities cover the required VLAN, multi-NIC, DHCP and IPv6 use cases without environment-specific defaults.
- Other Proxmox resources are added only where reusable consumer value is demonstrated.
- Public validation remains credential-free and compatibility claims match the evidence.

**Architecture dependencies:** Capability selection; provider and platform compatibility; resource, storage and network ownership; lifecycle and replacement behavior; public interfaces; validation and evidence requirements.

**Major deliverables:** Approved OpenTofu components, component documentation, focused public examples and credential-free validation.

**Risks / blockers:** Premature abstraction may produce monolithic interfaces. Storage and network changes can be destructive, and private-environment assumptions can become accidental defaults.

**Deferred work:** Guest and service configuration expansion, higher-level composition and live infrastructure evidence.

## M7 — Reusable guest and service configuration

**Goal:** Expand reusable Ansible capabilities beyond the initial guest-agent role.

**Why:** Consumers need repeatable guest and service configuration without turning the toolkit into an unbounded role catalog.

**Entry criteria:** M6 is complete, demonstrated consumer needs are identified, and Architecture has accepted the boundaries and evidence requirements for the selected guest and service capabilities.

**Exit criteria:**

- Approved common guest baseline and administration capabilities are independently reusable, documented and validated.
- Service roles exist only for demonstrated reusable needs.
- User or developer environment bootstrap is explicit, optional and limited to appropriate guest types; service-only and appliance guests are never included implicitly.
- Each capability documents prerequisites, lifecycle ownership, idempotency expectations and validation evidence.
- No capability assumes private inventory, secrets or topology.

**Architecture dependencies:** Capability selection; role boundaries; guest platform support; privilege and secrets boundaries; public interfaces; idempotency and evidence requirements.

**Major deliverables:** Approved Ansible roles, role documentation, focused public examples and credential-free validation.

**Risks / blockers:** Role-catalog sprawl, hidden distribution assumptions, excessive privilege and environment-specific behavior.

**Deferred work:** External-dotfiles integration, higher-level composition and live infrastructure evidence.

## M8 — Composition and ecosystem integration

**Goal:** Provide reusable composition patterns and optional ecosystem integrations without crossing lifecycle boundaries.

**Why:** Consumers need clear ways to combine toolkit capabilities while retaining control of deployment-specific state and choices.

**Entry criteria:** M6 and M7 capabilities are available, and Architecture has accepted the required handoff, composition and optional integration boundaries.

**Exit criteria:**

- Cross-component handoffs and lifecycle ownership remain explicit.
- Public examples demonstrate approved multi-component composition without hidden state or generated-inventory assumptions.
- Any external-dotfiles integration is generic, optional, disabled by default, configurable with a consumer-supplied repository and never used for secrets.
- Guest eligibility for dotfiles is explicit, and the consumer chooses the compatible repository without a toolkit recommendation or default.
- Ecosystem integrations remain optional and do not make the toolkit depend on a private deployment repository.
- Separate deployment repository patterns remain generic and public-safe.

**Architecture dependencies:** Composition and handoff contracts; dotfiles interface and enablement policy; guest eligibility; external revision and compatibility handling; security and validation requirements.

**Major deliverables:** Composition guidance, public examples, approved optional integrations and supporting documentation and validation.

**Risks / blockers:** Hidden coupling, duplicated lifecycle ownership, implicit inventory generation, ecosystem lock-in and accidental secret distribution.

**Deferred work:** Isolated live integration evidence and broader release maturity.

## M9 — Integration confidence and compatibility expansion

**Goal:** Add evidence-backed confidence for supported compositions and reference platforms.

**Why:** Credential-free validation proves contracts, but selected live evidence may be needed before broader compatibility claims are credible.

**Entry criteria:** M8 compositions are stable enough to test, and Architecture has accepted the scope and isolation model for any live validation.

**Exit criteria:**

- Compatibility claims are tied to documented evidence and explicit non-claims.
- Approved reference-platform evidence covers the selected reusable workflows.
- Any live testing is isolated, opt-in and separate from normal credential-free public CI.
- Credential custody, triggering, cleanup, failure handling and cost boundaries are documented for live validation.
- Troubleshooting guidance reflects observed integration behavior.

**Architecture dependencies:** Reference-platform scope; credential custody; test triggers and isolation; infrastructure ownership; cleanup and failure behavior; compatibility evidence thresholds.

**Major deliverables:** Integration evidence, compatibility documentation, isolated opt-in validation where approved, and evidence-based troubleshooting guidance.

**Risks / blockers:** Credential exposure, test flakiness, infrastructure cost, incomplete cleanup and compatibility overclaims.

**Deferred work:** Mandatory live public CI and stable-release commitments not supported by evidence.

## M10 — Release maturity and stable-readiness

**Goal:** Make ongoing releases predictable and determine whether the toolkit is ready for a stable compatibility commitment.

**Why:** Broader use requires repeatable releases, understandable changes and evidence-based compatibility expectations.

**Entry criteria:** M9 evidence is available and Architecture has accepted the required release, versioning and compatibility policies.

**Exit criteria:**

- Public interfaces and supported compatibility are versioned and documented.
- Releases, changelogs and migration guidance are repeatable.
- Upgrade expectations and compatibility non-claims are explicit.
- Project maintenance and open-source contribution paths support continued releases.
- A stable-readiness assessment records whether a 1.0 commitment is justified; no stable release is implied by this milestone.

**Architecture dependencies:** Versioning; release channels; compatibility guarantees and non-guarantees; changelog and migration policy; upgrade expectations; distribution and release mechanics.

**Major deliverables:** Repeatable releases, maintained compatibility information, migration guidance, contributor-facing release documentation, maturity and discoverability guidance, and a stable-readiness assessment.

**Risks / blockers:** Premature compatibility commitments, unsupported upgrade promises and release maintenance burden.

**Deferred work:** A 1.0 release until evidence and maintenance capacity justify its guarantees.

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
- **Capability expansion:** selected Proxmox, guest and service boundaries, lifecycle behavior and evidence requirements.
- **Composition and ecosystem:** cross-component handoffs, optional integrations and public/private boundaries.
- **Integration confidence:** reference-platform scope, live-test isolation and evidence thresholds.
- **Release:** versioning, compatibility, changelog, migration and release decisions.

## Near-term Developer work

Near-term Developer work implements M5 through focused GitHub Issues derived from the accepted first pre-release contract. Issue-level scope, dependencies and execution state live in GitHub. M6 and later milestones remain planning horizons until their required Architecture is accepted.

## Deferred from current execution

The following remains outside current M5 execution. Later milestones describe intended outcomes only; implementation still requires accepted Architecture and focused Issues.

- Proxmox and Ansible expansion beyond the first validated slice.
- Generic dotfiles integration.
- Live Proxmox testing outside an approved isolated path.
- Stable 1.0 compatibility commitment.
- Automated infrastructure apply.
- Concrete private deployment configuration.
- Registry publication.
- Higher-level composition abstractions.
- Additional providers or virtualization platforms.
