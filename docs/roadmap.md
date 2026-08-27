# Homelab IaC Toolkit Roadmap

## Purpose and authority

This roadmap translates approved architecture into implementation sequencing for the public Homelab IaC Toolkit. It defines the project phase, milestone sequence, milestone outcomes, major dependencies, deferred work, and roadmap maintenance policy.

Accepted Architecture Decision Records (ADRs) and architecture documentation outrank this roadmap. Once created, GitHub Issues become authoritative for detailed implementation scope, execution status, blockers, and implementation discussion. This roadmap remains authoritative for milestone-level planning and the current project phase. Architecture changes may require roadmap reconciliation.

The detailed M1 ticket definitions in this initial version are provisional execution definitions. They remain here only while no M1 GitHub Issues exist. Once those Issues become authoritative, the duplicated ticket bodies must be replaced with a compact linked issue index.

## Current project phase and readiness

**Current phase:** Architecture persistence and public repository bootstrap.

**Roadmap:** Approved for durable persistence.

**Implementation:** Blocked on Architecture persistence.

No Developer implementation ticket is Ready until:

1. Architecture persists AP-001 and AP-002.
2. Governance accepts those committed artifacts.
3. Roadmap reconciles provisional references with the accepted ADRs and architecture documentation.

The repository currently has a minimal [README](../README.md), [Apache License 2.0](../LICENSE), and protected default branch. It does not yet have accepted ADR files, committed architecture documentation, implementation Issues, active Milestones, or public validation workflows.

## Roadmap principles

- Architecture precedes implementation.
- Safety and repository foundations precede reusable features.
- Direct, reproducible local validation precedes CI enforcement.
- Public CI must require no private infrastructure or credentials.
- OpenTofu owns infrastructure lifecycle; Ansible owns guest configuration.
- Task coordinates workflows but owns no state or configuration.
- SOPS and age define the secrets interface; the public repository contains no real secrets or identities.
- Public examples use reserved or fictional values.
- Work is split into independently implementable and reviewable tickets.
- Documentation evolves with public interfaces and user-visible behavior.
- GitHub execution objects are created only as architecture maturity and execution proximity justify them.

## Architecture prerequisites

Architecture prerequisites are not Developer implementation tickets and do not receive `HTK-XXX` identifiers.

### AP-001 — Materialize the approved ADR set

**Resolution owner:** Architecture

Commit the ten already-approved decisions as ADRs with an index and clickable relative links:

- Public toolkit/private deployment separation.
- OpenTofu/Ansible lifecycle ownership.
- Caller-owned providers and backends.
- Repository-wide semantic versioning.
- Credential-free public CI.
- Executable fake-value examples.
- SOPS and age secrets interface.
- Task as orchestration only.
- Optional isolated live integration testing.
- Immutable release pinning.

**Unblock condition:** Governance accepts the committed ADR set.

### AP-002 — Materialize the architecture and repository design

**Resolution owner:** Architecture

Commit the approved architecture overview and repository design. It must link every cited ADR directly, define repository boundaries and lifecycle ownership, document the public/private model, and avoid unresolved provider, module, role, or tooling choices.

**Unblock condition:** Governance accepts the committed architecture documentation.

### AP-003 — Decide the Code of Conduct policy

**Resolution owner:** Architecture

Record `ADOPT`, `DEFER`, or `REJECT` with rationale. If adopted, identify the approved standard or policy source. Roadmap creates an implementation ticket only after `ADOPT`.

### AP-004 — Approve GitHub repository identity metadata

**Resolution owner:** Architecture

Approve the exact repository description, topics, homepage/project URL if any, and public maturity wording.

### AP-005 — Approve merge and baseline ruleset policy

**Resolution owner:** Architecture

Approve merge methods, review requirements, review-thread resolution, administrator/bypass policy, optional signed-commit or linear-history requirements, and controls deferred until CI exists.

### AP-006 — Approve the security-disclosure mechanism

**Resolution owner:** Architecture

Approve the supported disclosure mechanism or mechanisms, whether GitHub Private Vulnerability Reporting should be used, any approved alternative, and supported-version or response-expectation wording. Roadmap and Developer must not assume email or invent a generic contact channel.

### AP-007 — Approve GitHub Actions security architecture

**Resolution owner:** Architecture

Approve:

- Default `GITHUB_TOKEN` permissions.
- Workflow-level permission policy.
- Fork pull-request behavior.
- Third-party action policy.
- Immutable action-pinning requirements.
- Secret availability rules.
- Permitted use of `pull_request`.
- Whether `pull_request_target` is prohibited or allowed under narrowly documented conditions.

AP-007 blocks detailed M3 CI tickets.

## Project roadmap overview

The dependency sequence is:

`durable architecture → public/safe repository → local validation → credential-free CI → reusable capabilities → consumer/release contract → optional integration`

| Sequence | Milestone | Horizon | Observable outcome |
| --- | --- | --- | --- |
| Prerequisite | Architecture Persistence | Immediate | Approved ADRs and architecture documentation are committed and accepted. |
| 1 | M1 — Public Project Contract | Near term | Public identity, documentation navigation, safe structure, contributor/security entry points, and approved GitHub configuration exist. |
| 2 | M2 — Reproducible Local Validation | Near/medium term | Contributors can install approved tools and run direct credential-free validation locally. |
| 3 | M3 — Credential-Free Public CI | Medium term | GitHub Actions safely runs the same validation, and protected `main` requires stable checks. |
| 4 | M4 — First Reusable Toolkit Slice | Medium term | The first approved OpenTofu and Ansible capabilities are reusable, documented, and validated. |
| 5 | M5 — Consumer and Pre-1.0 Release Contract | Medium/long term | A private deployment repository can consume pinned toolkit releases through documented interfaces. |
| 6 | M6 — Optional Integration and Maturity Expansion | Long term | Selected lifecycle behavior is tested against isolated infrastructure and proven abstractions expand carefully. |

## Milestone definitions

### M1 — Public Project Contract

**Goal:** Establish a navigable, public-safe repository whose purpose, architecture, contribution model, documentation, and GitHub behavior are explicit.

**Why now:** The repository is minimal. Implementation before durable architecture would require Developer to infer design.

**Entry criteria:**

- [ ] AP-001 is complete and Governance-accepted.
- [ ] AP-002 is complete and Governance-accepted.
- [ ] Roadmap references are reconciled with committed artifacts.

**Exit criteria:**

- [ ] README is the primary public landing page.
- [ ] A documentation index/navigation entry point exists.
- [ ] All current user, contributor, security, and architecture documentation is reachable from README or the documentation index.
- [ ] No implemented documentation is orphaned.
- [ ] Planned documentation is clearly marked as planned and does not imply implemented functionality.
- [ ] Internal repository references are clickable.
- [ ] ADR mentions link directly to ADRs.
- [ ] Repository purpose, scope, maturity, and public/private boundaries are clear.
- [ ] Approved repository structure exists without speculative implementation.
- [ ] Ignore and editor rules protect state, plans, identities, and decrypted material.
- [ ] Contribution and security-reporting guidance exists.
- [ ] PR and issue templates require sanitized, public-safe information.
- [ ] Apache 2.0 licensing is referenced consistently.
- [ ] Approved GitHub metadata and baseline merge/ruleset settings are applied.
- [ ] No private environment data, credentials, inventory, state, or sensitive plans are present.

**Dependencies:** AP-001 through AP-006 as applicable.

**Deliverables:** README landing page, documentation navigation, architecture/ADR links, approved repository skeleton, ignore/editor rules, contribution/security guidance, PR/issue templates, repository metadata, and merge/ruleset baseline.

**Risks:** Architecture drift in documentation, speculative scaffolding, overbroad ignore rules, non-operational disclosure guidance, and ruleset lockout.

**Deferred/non-goals:** Tool setup, validation, CI workflows, modules, roles, examples, deployment, private configuration, and a Code of Conduct unless AP-003 results in `ADOPT`.

### M2 — Reproducible Local Validation

**Goal:** Provide direct, documented, credential-free validation for repository-owned artifacts, with Task as a transparent facade.

**Why now:** CI should enforce checks that already work locally.

**Entry criteria:**

- [ ] M1 is complete.
- [ ] Tool-version and compatibility policy is approved.
- [ ] Policy-bearing validation-tool choices are approved.

**Exit criteria:**

- [ ] Getting Started and prerequisites guides exist.
- [ ] Local tool installation/setup is documented.
- [ ] Repository safety checks are executable.
- [ ] OpenTofu formatting and backend-disabled validation are executable.
- [ ] Ansible lint and syntax validation are executable without live hosts.
- [ ] Documentation link/reference validation is executable where practical.
- [ ] Task exposes checks without hiding direct commands.
- [ ] Aggregate validation is credential-free and non-destructive.
- [ ] Validation troubleshooting is documented.
- [ ] Documented commands are verified.

**Dependencies:** Tool/version policy, provider decision before provider-dependent fixtures, validation-tool policy, and documentation-link validation approach.

**Deliverables:** Getting Started, prerequisites/setup, compatibility policy, direct validation helpers, Task workflow, testing/troubleshooting guides, and justified sanitized fixtures.

**Risks:** Network-dependent tool installation, accidental live-provider assumptions, opaque Task behavior, and fragile link checking.

**Deferred/non-goals:** Live Proxmox testing, deployment commands, secret decryption, and unapproved convergence frameworks.

### M3 — Credential-Free Public CI

**Goal:** Enforce approved local validation on pull requests and protected `main` using the AP-007 security model.

**Why now:** CI must protect reusable lifecycle code before it is introduced.

**Entry criteria:**

- [ ] M2 is complete.
- [ ] AP-007 is complete.
- [ ] Aggregate local validation is stable.
- [ ] Required check names are known.

**Exit criteria:**

- [ ] CI runs approved validation on appropriate events.
- [ ] Default and workflow token permissions match AP-007.
- [ ] Fork behavior matches AP-007.
- [ ] Third-party actions comply with approved policy.
- [ ] Actions are immutably pinned where required.
- [ ] No private infrastructure or deployment credentials are required.
- [ ] `pull_request_target` is absent unless explicitly approved and constrained.
- [ ] Required checks are attached to protected `main`.
- [ ] A public fork can run normal validation safely.
- [ ] CI behavior and troubleshooting are documented.
- [ ] Dependency updates are implemented or explicitly deferred.

**Dependencies:** AP-007, credential-free CI ADR, dependency-update policy, and applicable GitHub security decisions.

**Deliverables:** Baseline validation workflow, workflow-policy checks, CI documentation, required-check ruleset update, and approved dependency-update configuration.

**Risks:** Supply-chain compromise, excessive permissions, unsafe fork behavior, secret exposure, and check-name/ruleset mismatch.

**Deferred/non-goals:** Live infrastructure tests, deployment/release workflows, private runners, and SOPS decryption.

### M4 — First Reusable Toolkit Slice

**Goal:** Deliver the first Architecture-approved OpenTofu and Ansible capabilities with small, documented, experimental interfaces.

**Why now:** Reusable functionality follows architecture, validation, and CI foundations.

**Entry criteria:**

- [ ] M1 through M3 are complete.
- [ ] First module and role scopes are approved.
- [ ] Provider and supported-platform constraints are approved.
- [ ] Interface and testing expectations are committed.

**Exit criteria:**

- [ ] The first approved infrastructure module passes required validation.
- [ ] The first approved guest-configuration capability passes required validation.
- [ ] Provider and backend ownership remains with consumers.
- [ ] OpenTofu does not perform guest configuration.
- [ ] Ansible does not own Proxmox lifecycle.
- [ ] Interfaces, defaults, platforms, and lifecycle risks are documented.
- [ ] User workflows and public-safe examples are navigable.
- [ ] Maturity and limitations are explicit.

**Dependencies:** First module interface, first role scope, provider selection, supported guest platforms, and test strategy.

**Deliverables:** First approved module, first approved role/capability, focused examples, and interface/workflow documentation.

**Risks:** Premature abstraction, resource replacement, overstated provider validation, and non-portable guest defaults.

**Deferred/non-goals:** Complete topology, broad service catalog, opinionated private environments, and mandatory dotfiles integration.

### M5 — Consumer and Pre-1.0 Release Contract

**Goal:** Allow a private deployment repository to consume immutable toolkit versions through documented interfaces.

**Why now:** Consumer and release contracts become meaningful after reusable interfaces exist.

**Entry criteria:**

- [ ] M4 is complete.
- [ ] Interfaces have implementation feedback.
- [ ] SOPS/age and distribution mechanisms are approved.

**Exit criteria:**

- [ ] Consumer setup is documented.
- [ ] Public/private repository responsibilities are operationally clear.
- [ ] OpenTofu examples validate as external roots.
- [ ] Ansible consumption is reproducible.
- [ ] SOPS and age guidance uses only fake recipients/placeholders.
- [ ] Compatibility/support policy is published.
- [ ] Release/version usage is documented.
- [ ] Changelog and migration policy exist.
- [ ] Pre-1.0 readiness is assessable without private credentials.

**Dependencies:** Ansible distribution mechanism, public SOPS/age schema, compatibility posture, and release/publishing scope.

**Deliverables:** Consumer guide, examples index, secrets guide, compatibility matrix, versioning, changelog, and upgrade guidance.

**Risks:** Production misuse of examples, secrets entering state, incorrect compatibility promises, and mutable source references.

**Deferred/non-goals:** Private deployment implementation, real inventory/endpoints/recipients/secrets, and stable 1.0 guarantees.

### M6 — Optional Integration and Maturity Expansion

**Goal:** Add isolated lifecycle evidence and expand only abstractions justified by consumers.

**Why now:** Live tests and broader abstractions are costly and risky.

**Entry criteria:**

- [ ] M5 is complete.
- [ ] Dedicated isolated test capability exists.
- [ ] Credential, cleanup, naming, and recovery safeguards are approved.
- [ ] A concrete lifecycle behavior justifies live testing.

**Exit criteria:**

- [ ] Tests target isolated resources only.
- [ ] Unique naming and low-privilege credentials are enforced.
- [ ] Cleanup and recovery are documented.
- [ ] Static validation remains normal public CI.
- [ ] New abstractions are supported by repeated needs.
- [ ] Dotfiles documentation exists only if a generic integration is approved and implemented.

**Dependencies:** Integration environment design, credential delivery, cleanup/recovery contract, and maturity evidence.

**Deliverables:** Optional integration harness, recovery guidance, evidence-backed capabilities, and maturity-promotion records.

**Risks:** Resource destruction, information leakage, test leftovers, and speculative abstraction growth.

**Deferred/non-goals:** General-purpose homelab testing, private infrastructure as a contribution requirement, and broad workload deployment.

## Documentation and user-guide strategy

Documentation evolves with functionality and is part of Definition of Done.

A ticket cannot be Done until relevant documentation is reconciled when it changes a public interface, contributor workflow, supported behavior, compatibility, user command, configuration, example, or lifecycle behavior. Breaking interface changes must update migration guidance in the same change.

| Phase | Required documentation |
| --- | --- |
| Architecture prerequisite | ADR index, ADRs, architecture overview, repository design. |
| M1 | README, docs navigation, scope/maturity, contribution guide, security guide, reference policy. |
| M2 | Getting Started, prerequisites, local setup, Task/OpenTofu/Ansible validation workflows, troubleshooting. |
| M3 | CI behavior, fork behavior, permissions, required checks, CI troubleshooting, dependency policy. |
| M4 | Module/role references, user workflows, examples, supported behavior, lifecycle risks, maturity/limitations. |
| M5 | Consumer setup, public/private model, SOPS/age usage, compatibility/support, releases, changelog, upgrades/migrations. |
| M6 | Integration operation/recovery and a dotfiles guide only if implemented. |

Planned navigation includes Getting Started, prerequisites/setup, architecture, public/private model, OpenTofu, Ansible, Task, SOPS/age, examples, consumer setup, compatibility, troubleshooting, releases, upgrades, security, maturity/limitations, and optional dotfiles integration. Planned pages must not imply functionality exists.

## Reference and linking policy

- Use relative Markdown links for repository files.
- Link every ADR mention directly once the ADR paths exist.
- Link README and indexes to relevant guides, examples, and references.
- Link GitHub Issues, PRs, commits, Milestones, and Releases directly when referenced.
- Prefer canonical official upstream documentation.
- Prefer the exact relevant documentation page over a project homepage.
- For version-specific behavior, link versioned documentation where practical.
- Avoid unstable or unofficial sources for normative behavior.
- Do not leave implemented documentation orphaned.
- Update inbound links when moving or renaming documentation.
- Link interface documentation to applicable examples.
- Link migration guides to affected releases and interfaces.
- Validate links manually in M1, locally where practical in M2, and in CI in M3.

ADR links are intentionally unresolved until AP-001 and AP-002 are persisted. Roadmap must reconcile them afterward rather than fabricating paths.

## Provisional M1 implementation tickets

These are provisional execution definitions. They are blocked until their stated prerequisites are satisfied. Developer owns implementation after a ticket becomes Ready; Architecture resolves architecture prerequisites; Roadmap reconciles implementation dependencies.

### HTK-001 — Establish documentation navigation and linking

- **Status:** Blocked
- **Objective:** Create the documentation entry point and linking conventions.
- **Scope:** Add the docs index, link accepted architecture, record reference rules, and identify future guides without misleading placeholder content.
- **Non-goals:** Rewrite Architecture content, select a link checker, or document unimplemented behavior.
- **Dependencies:** AP-001, AP-002.
- **Dependency type:** Architecture.
- **Acceptance criteria:** One entry point; direct ADR links; relative repository links; direct GitHub links; canonical/versioned normative references; no orphan docs; planned content clearly identified.
- **Validation:** Follow internal links, find unlinked ADR mentions/orphans, and review external references.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** No private repositories, topology, state, plans, or credentials.
- **Destructive impact:** NONE.
- **Blocked by:** AP-001, AP-002.
- **Resolution owner:** Architecture.
- **Implementation owner:** Developer.
- **Unblock condition:** Governance accepts AP-001 and AP-002.

### HTK-002 — Expand README into the public landing page

- **Status:** Blocked
- **Objective:** Provide an accurate landing page for users and contributors.
- **Scope:** State purpose, audience, stack, boundaries, maturity, limitations, and link current docs/license.
- **Non-goals:** Detailed deployment instructions, unimplemented claims, or unsupported compatibility promises.
- **Dependencies:** HTK-001.
- **Dependency type:** Implementation.
- **Acceptance criteria:** README is primary landing page; all current docs reachable; references clickable; implemented/planned distinction accurate.
- **Validation:** Follow links, compare with architecture, verify claimed artifacts/commands, and check public safety.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** No private hosts, addresses, identifiers, plans, or topology.
- **Destructive impact:** NONE.
- **Blocked by:** HTK-001.
- **Resolution owner:** Roadmap.
- **Implementation owner:** Developer.
- **Unblock condition:** HTK-001 is Done.

### HTK-003 — Create the approved repository skeleton

- **Status:** Blocked
- **Objective:** Add only structural areas approved by Architecture.
- **Scope:** Create approved docs, OpenTofu, Ansible, schema, helper, and GitHub-configuration areas with minimal purpose text where needed.
- **Non-goals:** Functional modules, roles, workflows, examples, private environments, providers, or backends.
- **Dependencies:** AP-001, AP-002.
- **Dependency type:** Architecture.
- **Acceptance criteria:** Tree matches design; placeholders explain purpose; docs are reachable where applicable; no environment-specific or executable implementation.
- **Validation:** Compare tree with AP-002, check prohibited paths, and follow links.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** No realistic provider, inventory, variable, or secret content.
- **Destructive impact:** NONE.
- **Blocked by:** AP-001, AP-002.
- **Resolution owner:** Architecture.
- **Implementation owner:** Developer.
- **Unblock condition:** Governance accepts both prerequisites.

### HTK-004 — Add public-safe ignore and editor conventions

- **Status:** Blocked
- **Objective:** Protect sensitive/generated files and establish portable text conventions.
- **Scope:** Narrow ignores for state, plans, caches, retries, decrypted material, age identities, editors, and relevant OS artifacts; minimal editor rules.
- **Non-goals:** Delete files, rewrite history, or select scanners/tool versions.
- **Dependencies:** AP-001, AP-002.
- **Dependency type:** Architecture.
- **Acceptance criteria:** Sensitive/generated patterns covered; approved encrypted/source files remain trackable; existing tracked files remain visible; explanations linked; validation deletes nothing.
- **Validation:** Test fictional filenames, review wildcard scope, and verify tracked files.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** Report filenames only, never contents.
- **Destructive impact:** LOW.
- **Blocked by:** AP-001, AP-002.
- **Resolution owner:** Architecture.
- **Implementation owner:** Developer.
- **Unblock condition:** Governance accepts both prerequisites.

### HTK-005 — Add the contributor guide

- **Status:** Blocked
- **Objective:** Explain small, validated, architecture-aligned, public-safe contributions.
- **Scope:** Contribution flow, lifecycle ownership, architecture escalation, sanitized evidence, documentation impact, and existing validation.
- **Non-goals:** Code of Conduct selection, CLA/DCO policy, or future commands.
- **Dependencies:** HTK-001, HTK-002.
- **Dependency type:** Implementation.
- **Acceptance criteria:** Boundaries explicit; docs part of completion; architecture changes escalated; references clickable; only real commands/paths; sensitive artifacts prohibited.
- **Validation:** Follow links, compare architecture, verify commands/paths, and review sanitization guidance.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** Cover plans, state, logs, identities, endpoints, inventories, and topology.
- **Destructive impact:** NONE.
- **Blocked by:** HTK-001, HTK-002.
- **Resolution owner:** Roadmap.
- **Implementation owner:** Developer.
- **Unblock condition:** Both dependencies are Done.

### HTK-006 — Add security policy and approved disclosure mechanism

- **Status:** Blocked
- **Objective:** Define safe reporting using the AP-006 mechanism.
- **Scope:** Report categories, sensitive-report redirection, approved mechanisms, accurate support wording, and authoritative references.
- **Non-goals:** Choose the mechanism, invent SLAs/bounties, or add scanning.
- **Dependencies:** AP-006, HTK-001, HTK-002.
- **Dependency type:** Architecture and Implementation.
- **Acceptance criteria:** Mechanism operational; sensitive public disclosure prohibited; maturity accurate; references canonical/clickable; README/docs link policy; settings verified if applicable.
- **Validation:** Verify mechanism, links, maturity wording, and applicable GitHub settings.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** Unverified placeholders cannot be presented as operational.
- **Destructive impact:** LOW.
- **Blocked by:** AP-006, HTK-001, HTK-002.
- **Resolution owner:** Architecture for AP-006; Roadmap for implementation dependencies.
- **Implementation owner:** Developer.
- **Unblock condition:** AP-006 is approved and both HTK dependencies are Done.

### HTK-007 — Add the pull-request template

- **Status:** Blocked
- **Objective:** Prompt for scope, validation, documentation, architecture alignment, risks, and safety.
- **Dependencies:** HTK-005.
- **Dependency type:** Implementation.
- **Acceptance criteria:** Documentation impact explicit; deviations/destructive behavior surfaced; ADRs/Issues linked; public-safety confirmation; concise rendering.
- **Validation:** Preview Markdown, follow links, and compare contributor guidance.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** Warn that raw plans, state, and logs may be sensitive.
- **Destructive impact:** NONE.
- **Blocked by:** HTK-005.
- **Resolution owner:** Roadmap.
- **Implementation owner:** Developer.
- **Unblock condition:** HTK-005 is Done.

### HTK-008 — Add focused public-safe issue templates

- **Status:** Blocked
- **Objective:** Provide defect/feature entry points and redirect sensitive reports.
- **Dependencies:** HTK-005, HTK-006.
- **Dependency type:** Implementation.
- **Acceptance criteria:** Distinct templates; approved disclosure routing; private artifacts prohibited; reusable value required; clickable references; no unavailable commands.
- **Validation:** Validate syntax, preview templates, follow links, and compare policy docs.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** Request sanitized excerpts only.
- **Destructive impact:** NONE.
- **Blocked by:** HTK-005, HTK-006.
- **Resolution owner:** Roadmap.
- **Implementation owner:** Developer.
- **Unblock condition:** Both dependencies are Done.

### HTK-009 — Apply approved GitHub repository metadata

- **Status:** Blocked
- **Objective:** Apply AP-004 description, topics, homepage, and maturity wording.
- **Dependencies:** AP-004, HTK-002.
- **Dependency type:** Architecture and Implementation.
- **Acceptance criteria:** Metadata matches AP-004/README; no unsupported maturity claim; homepage valid; required Issues/PR features enabled.
- **Validation:** Read back metadata, compare approved values, and follow homepage.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** No private URLs, identifiers, or environment metadata.
- **Destructive impact:** LOW.
- **Blocked by:** AP-004, HTK-002.
- **Resolution owner:** Architecture for AP-004; Roadmap for HTK-002.
- **Implementation owner:** Developer.
- **Unblock condition:** AP-004 approved and HTK-002 Done.

### HTK-010 — Reconcile baseline merge and ruleset configuration

- **Status:** Blocked
- **Objective:** Apply AP-005 merge methods and default-branch protections.
- **Dependencies:** AP-005, HTK-005.
- **Dependency type:** Architecture and Implementation.
- **Acceptance criteria:** Settings match AP-005; merge behavior matches contributor docs; no nonexistent CI required; settings read back; docs updated.
- **Validation:** Read back settings/ruleset, compare AP-005, and verify contributor documentation.
- **Documentation impact:** UPDATE REQUIRED.
- **Public safety:** Do not weaken protections beyond approved policy.
- **Destructive impact:** MEDIUM.
- **Blocked by:** AP-005, HTK-005.
- **Resolution owner:** Architecture for AP-005; Roadmap for HTK-005.
- **Implementation owner:** Developer.
- **Unblock condition:** AP-005 approved and HTK-005 Done.

Every provisional ticket uses this Definition of Done: implementation complete; acceptance criteria satisfied; validation passes; required documentation is reconciled in the same change; no unresolved architecture deviation; and the relevant PR/CI is complete.

## Dependency graph

```text
AP-001 ─┬─> HTK-001 ─> HTK-002 ─┬─> HTK-005 ─> HTK-007
AP-002 ─┘                        │      │
   │                             │      └──────────────┐
   ├────────> HTK-003            └─> HTK-006 <─ AP-006│
   └────────> HTK-004                    │             │
                                        └─────────────> HTK-008

AP-004 + HTK-002 ─> HTK-009
AP-005 + HTK-005 ─> HTK-010
AP-003 ─> Code of Conduct ticket only if ADOPT
AP-007 ─> M3 CI ticket decomposition
```

After AP-001 and AP-002, HTK-001, HTK-003, and HTK-004 may proceed in parallel. HTK-002 follows HTK-001. HTK-005 and HTK-006 may proceed in parallel after their dependencies. HTK-007 and HTK-008 follow the policies they operationalize. HTK-009 and HTK-010 are independently blocked by their GitHub-setting decisions.

## GitHub-side configuration coverage

| Configuration | Milestone | Authority and treatment |
| --- | --- | --- |
| Description/topics/homepage | M1 | AP-004 → HTK-009 |
| Issue and PR availability | M1 | Verify during HTK-009 |
| PR template | M1 | HTK-007 |
| Issue templates/chooser | M1 | HTK-008 |
| Security-disclosure feature | M1 | AP-006 → HTK-006 |
| Merge methods | M1 | AP-005 → HTK-010 |
| Baseline `main` ruleset | M1 | AP-005 → HTK-010 |
| Default Actions permissions | M3 | AP-007 |
| Workflow permissions | M3 | AP-007 plus CI acceptance criteria |
| Fork PR behavior | M3 | AP-007 |
| Action pinning/third-party policy | M3 | AP-007 |
| Secret availability/event policy | M3 | AP-007 |
| Required CI checks | M3 | Apply after check names stabilize |
| Dependency updates | M3/M4 | Pending Architecture policy |
| Other security settings | M3+ | Only when explicitly approved |
| Release/tag protection | M5 | Pending release policy |

Developer applies GitHub configuration only after Architecture specifies the desired state.

## Remaining architecture blockers

- Supported tool versions and version-manifest format.
- Proxmox provider and constraints.
- First OpenTofu interface.
- First Ansible capability and supported platforms.
- Lint, scanner, link-check, and convergence tooling.
- Public SOPS and age schema.
- Ansible distribution mechanism.
- Dependency-update policy.
- Pre-1.0 compatibility and release policy.
- Tag/release protection.
- Live integration contract.
- Generic external-dotfiles interface.
- Additional GitHub security settings.

## Deferred work

- VM/LXC modules.
- Concrete provider configuration.
- Ansible roles.
- Convergence framework.
- Secret scanner.
- Automated dependency updates.
- Release automation.
- Live Proxmox tests.
- Private deployment implementation.
- Private DNS, Tailscale, Cloudflare, or personal topology.
- Dotfiles capability.
- Code of Conduct implementation pending AP-003.
- M3 CI tickets pending AP-007.
- M4 through M6 detailed decomposition.

## Highest-priority Ready ticket

None. No Developer ticket is Ready until AP-001 and AP-002 are accepted.

The expected first Ready candidate afterward is HTK-001 because it makes Architecture-owned artifacts discoverable and establishes reference rules for subsequent documentation.

## Durable roadmap model

This file owns:

- Roadmap principles and current phase.
- Milestone sequence and outcomes.
- Milestone entry/exit criteria.
- Major dependencies and architecture blockers.
- Deferred work.
- Documentation strategy.
- GitHub configuration coverage.
- Links to active GitHub Milestones and Issues once created.

GitHub Issues own detailed implementation tickets, execution status, immediate blockers, implementation discussion, linked PRs, and validation evidence. GitHub Milestones own execution grouping for active or near-term milestones.

When M1 Issues become authoritative, replace the provisional full ticket definitions above with a compact linked issue index. Do not maintain a duplicate ticket-status table here.

## GitHub Issues and Milestones model

### Issues

- Backlog: open issue without Ready/Blocked status label.
- Ready: `status:ready`.
- In Progress: assigned issue with a linked implementation PR.
- Blocked: `status:blocked` with explicit blockers.
- Done: closed only after Definition of Done.

Initial labels should remain minimal: `status:ready`, `status:blocked`, `area:documentation`, `area:repository`, and `area:security`. Add tool-specific area labels only when those tickets exist.

### Milestones

- Create M1 only when AP-001/AP-002 are accepted and implementation is ready to begin.
- Create later GitHub Milestones only when their prerequisites are sufficiently resolved and execution is approaching.
- Keep the future milestone sequence visible here without creating premature GitHub commitments.
- Link active Milestones from this file.
- Close a Milestone only when its exit criteria are satisfied, not merely when its Issues are closed.

## Roadmap maintenance policy

Update this roadmap when:

- Milestone definitions change.
- Architecture invalidates planned work.
- Milestone entry or exit criteria change.
- Major work is added, removed, or deferred.
- Major dependencies change.
- Architecture blockers are resolved or introduced.
- The current project phase changes.
- Active GitHub Milestone/Issue links need reconciliation.

Do not update it for every small ticket status transition once GitHub Issues own execution state.

Maintenance must preserve historical context, identify invalidated work, avoid a stale ticket table, keep links current, reconcile milestone outcomes, and preserve the public/private and lifecycle boundaries.
