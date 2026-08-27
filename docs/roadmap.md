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

Commit the approved architecture overview and repository design. It must link every cited ADR directly and explicitly record:

- The approved architecture overview.
- The approved repository design.
- Repository boundaries.
- Lifecycle ownership.
- The public/private repository model.
- The approved high-level documentation structure.

It must not add unresolved provider, module, role, or tooling choices.

**Unblock condition:** Governance accepts the committed architecture documentation.

### AP-003 — Decide the Code of Conduct policy

**Resolution owner:** Architecture

Record `ADOPT`, `DEFER`, or `REJECT` with rationale. If adopted, identify the approved standard or policy source. Roadmap creates an implementation ticket only after `ADOPT`.

### AP-004 — Approve GitHub repository identity metadata

**Resolution owner:** Architecture

Approve the exact repository description, topics, homepage/project URL if any, and public maturity wording.

### AP-005 — Approve merge and baseline ruleset policy

**Resolution owner:** Architecture

Approve:

- Allowed merge method or methods.
- Approval requirements.
- Review-thread resolution requirements.
- Administrator/bypass policy.
- Force-push policy.
- Branch-deletion policy.
- Signed-commit policy, if any.
- Linear-history policy, if any.
- Controls deferred until CI exists.

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

## Dotfiles cross-repository context

[mlznlv/dotfiles](https://github.com/mlznlv/dotfiles) is a separate public repository. Any Homelab IaC Toolkit capability for dotfiles must remain optional and expose a generic, vendor-neutral interface. Concrete selection of `mlznlv/dotfiles` belongs in the private deployment repository unless Architecture explicitly decides otherwise. Dotfiles must not distribute secrets.

Generic dotfiles integration remains Architecture-blocked and is not currently scheduled at ticket level. A dotfiles user guide becomes part of the documentation commitment only if the capability is approved and implemented.

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

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** Public documentation foundation

**Objective:** Create the documentation entry point and repository-wide linking conventions.

**Why:** Documentation must evolve with functionality, remain discoverable, and link directly to its sources of truth.

**Source-of-truth references:**

- AP-001 accepted ADRs, after Architecture persistence.
- AP-002 accepted architecture and repository design, after Architecture persistence.
- Approved documentation and reference requirements in this roadmap.

**Scope:**

- Add the documentation navigation/index.
- Link directly to every accepted ADR and architecture page after those paths exist.
- Define relative-link conventions for repository documentation.
- Define direct-link requirements for referenced GitHub Issues, PRs, and Releases.
- Require authoritative upstream links for external technical references.
- Establish navigation for future user guides without claiming they exist.

**Non-goals:**

- Rewriting Architecture-owned documents.
- Creating placeholder guides with invented behavior.
- Selecting a link-checking tool.
- Writing Getting Started or tool workflows before those workflows exist.

**Expected repository areas:**

- Architecture-approved documentation area.
- Contributor-facing documentation conventions.

**Dependencies:** AP-001, AP-002

**Dependency type:** Architecture

**Acceptance criteria:**

- [ ] Documentation has one clear entry point.
- [ ] Every ADR mention links directly to its ADR after AP reconciliation.
- [ ] Repository-file references use relative Markdown links.
- [ ] GitHub artifacts use direct links when referenced.
- [ ] External normative references are canonical, exact, and versioned where relevant.
- [ ] No implemented documentation is orphaned.
- [ ] Planned sections are not represented as implemented guides.

**Required validation:**

- Manually follow every internal link.
- Check for unlinked plain-text ADR references after AP reconciliation.
- Check for orphan pages.
- Confirm external references are authoritative and specific.
- Record link-check automation as M2 work rather than selecting a tool here.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Link targets and examples must not expose private repositories, plans, state, infrastructure identifiers, or credentials.

**Destructive impact:** NONE

**Blocked by:**

- AP-001
- AP-002

**Resolution owner:** Architecture

**Implementation owner:** Developer

**Unblock condition:** Governance accepts AP-001 and AP-002.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- Documentation index and reference policy are reconciled in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-002 — Expand README into the public landing page

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** Public documentation foundation

**Objective:** Turn the minimal README into an accurate public entry point.

**Why:** Visitors must understand the project purpose, maturity, boundaries, stack, and current implementation status.

**Source-of-truth references:**

- Accepted ADRs and architecture documentation after AP-001/AP-002.
- HTK-001 documentation navigation.
- Existing [Apache License 2.0](../LICENSE).

**Scope:**

- State project purpose and intended audience.
- Summarize the supported stack and lifecycle boundaries.
- Explain public toolkit/private deployment separation.
- Mark the repository as bootstrap/pre-release.
- Link current documentation, architecture, security guidance, contribution guidance, and license as those artifacts become available.
- Distinguish implemented from planned capabilities.

**Non-goals:**

- Detailed installation or deployment instructions.
- Claiming modules, roles, examples, CI, or Releases already exist.
- Adding badges for checks or Releases that do not exist.
- Unsupported compatibility commitments.

**Expected repository areas:**

- Root [README](../README.md).

**Dependencies:** HTK-001

**Dependency type:** Implementation

**Acceptance criteria:**

- [ ] README is the primary public landing page.
- [ ] Purpose, audience, maturity, and limitations are clear.
- [ ] Architecture and public/private boundaries match accepted artifacts.
- [ ] All repository-document references are clickable relative links.
- [ ] License reference is accurate.
- [ ] No nonexistent capability or guide is presented as available.
- [ ] All current user and contributor documentation is reachable from README or the docs index.

**Required validation:**

- Follow every README link.
- Compare scope language with accepted architecture.
- Verify every claimed artifact and command exists.
- Check for private or environment-specific data.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Avoid real environment screenshots, plans, hostnames, addresses, account identifiers, and private-repository links.

**Destructive impact:** NONE

**Blocked by:**

- HTK-001

**Resolution owner:** Roadmap

**Implementation owner:** Developer

**Unblock condition:** HTK-001 is Done.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- README and relevant navigation are reconciled in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-003 — Create the approved repository skeleton

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** Repository structure and publish safety

**Objective:** Add only the structural areas explicitly approved by Architecture.

**Why:** Future work needs stable ownership boundaries without prematurely encoding interfaces or environment structure.

**Source-of-truth references:**

- AP-001 accepted ADRs after persistence.
- AP-002 accepted repository design after persistence.

**Scope:**

- Create approved areas for documentation, OpenTofu, Ansible, schemas, validation helpers, and GitHub configuration.
- Retain otherwise-empty areas using short purpose documentation where necessary.
- Explain each area's lifecycle owner.
- Link purpose documentation from its parent or documentation index where useful.

**Non-goals:**

- Modules, roles, workflows, examples, test fixtures, or functional scripts.
- Private environments, inventories, provider configuration, or backends.
- Directories not justified by the accepted repository design.

**Expected repository areas:**

- Only paths explicitly defined by AP-002.

**Dependencies:** AP-001, AP-002

**Dependency type:** Architecture

**Acceptance criteria:**

- [ ] Structure matches accepted repository design.
- [ ] Every retained placeholder explains its purpose.
- [ ] Purpose documents are linked from their parent or index where appropriate.
- [ ] No environment-specific or private-deployment area exists.
- [ ] No executable infrastructure or guest-configuration implementation is included.
- [ ] Existing README, roadmap, and license remain intact.

**Required validation:**

- Inspect the repository tree against AP-002.
- Search for prohibited environment-oriented paths.
- Follow all links added by the change.
- Review placeholders for speculative claims.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Do not seed directories with realistic inventories, variables, provider settings, secret files, or plans.

**Destructive impact:** NONE

**Blocked by:**

- AP-001
- AP-002

**Resolution owner:** Architecture

**Implementation owner:** Developer

**Unblock condition:** Governance accepts AP-001 and AP-002.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- Purpose and navigation documentation are reconciled in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-004 — Add public-safe ignore and editor conventions

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** Repository structure and publish safety

**Objective:** Prevent common sensitive/generated artifacts from entering Git and establish portable text conventions.

**Why:** State, generated plans, decrypted material, private identities, and tool caches are immediate public-repository risks.

**Source-of-truth references:**

- AP-001 public/private separation and SOPS/age ADRs after persistence.
- Project public-safety requirements.

**Scope:**

- Add narrowly scoped ignore rules for approved toolchains and sensitive/generated artifacts.
- Cover OpenTofu state/plans, local caches, Ansible retry files, decrypted-secret conventions, age identities, and relevant editor/OS artifacts.
- Add portable editor settings.
- Document non-obvious ignore decisions.

**Non-goals:**

- Deleting ignored files.
- Rewriting Git history.
- Secret-scanner integration.
- Tool-version or formatting-tool selection.

**Expected repository areas:**

- Root repository hygiene and editor-configuration files.
- Relevant linked documentation.

**Dependencies:** AP-001, AP-002

**Dependency type:** Architecture

**Acceptance criteria:**

- [ ] Common state and plan artifacts are ignored.
- [ ] Age private identities and decrypted-secret conventions are ignored.
- [ ] Approved encrypted files and reusable source are not broadly ignored.
- [ ] Existing tracked files are not unintentionally hidden.
- [ ] Non-obvious rules have linked explanations.
- [ ] Validation performs no deletion.

**Required validation:**

- Exercise ignore rules with fictional filenames.
- Manually review wildcard patterns for overreach.
- Confirm existing tracked files remain visible.
- Validate links to explanatory documentation.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Checks report filenames only, never secret contents.
- Test names and values remain fictional.

**Destructive impact:** LOW

**Blocked by:**

- AP-001
- AP-002

**Resolution owner:** Architecture

**Implementation owner:** Developer

**Unblock condition:** Governance accepts AP-001 and AP-002.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- Non-obvious behavior is documented in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-005 — Add the contributor guide

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** Contributor and security entry points

**Objective:** Explain how to propose safe, architecture-aligned changes.

**Why:** Contributors need clear boundaries before functional work begins.

**Source-of-truth references:**

- Accepted ADRs and architecture documentation after AP persistence.
- HTK-001 documentation/reference policy.
- HTK-002 public project landing page.
- Project public-safety requirements.

**Scope:**

- Explain contribution workflow and preferred review size.
- Require public-safe examples and sanitized diagnostics.
- State architecture and lifecycle ownership rules.
- Describe current validation expectations without claiming unavailable commands.
- Explain when Architecture review is required.
- Make documentation impact part of contribution completeness.

**Non-goals:**

- Defining a Code of Conduct.
- Inventing commit-message, DCO, CLA, or review policies.
- Documenting validation that has not been implemented.

**Expected repository areas:**

- Contributor documentation.
- Documentation index links.

**Dependencies:** HTK-001, HTK-002

**Dependency type:** Implementation

**Acceptance criteria:**

- [ ] Public/private and lifecycle boundaries are explicit.
- [ ] Architecture-changing proposals require Architecture review.
- [ ] Documentation impact is part of contribution completeness.
- [ ] Repository references are clickable relative links.
- [ ] Only existing commands and paths are documented.
- [ ] State, plans, secrets, inventories, private topology, and unsanitized logs are prohibited.

**Required validation:**

- Follow every link.
- Compare guidance with accepted architecture.
- Verify every referenced path and command.
- Review sanitization requirements.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Sanitization guidance covers logs, plans, state, endpoints, topology, and identities.

**Destructive impact:** NONE

**Blocked by:**

- HTK-001
- HTK-002

**Resolution owner:** Roadmap

**Implementation owner:** Developer

**Unblock condition:** HTK-001 and HTK-002 are Done.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- Contributor and navigation documentation are reconciled in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-006 — Add security policy and approved disclosure mechanism

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** Contributor and security entry points

**Objective:** Define safe reporting using the Architecture-approved disclosure mechanism.

**Why:** Infrastructure reports can contain credentials, topology, plans, state, and other sensitive material.

**Source-of-truth references:**

- AP-006 approved security-disclosure mechanism.
- Accepted security and public/private architecture after AP persistence.
- HTK-001 reference policy.
- HTK-002 project maturity wording.

**Scope:**

- Define relevant security-report categories.
- Direct sensitive reports away from public Issues.
- Use the AP-006-approved mechanism, including GitHub Private Vulnerability Reporting if selected.
- Explain sanitization expectations and current supported-version maturity.
- Link authoritative security and support references.

**Non-goals:**

- Choosing email, Private Vulnerability Reporting, or another mechanism.
- Inventing a response SLA, bounty, embargo, or support guarantee.
- Adding automated security scanning.

**Expected repository areas:**

- Security policy.
- Documentation index and README links.
- Approved GitHub security setting, if applicable.

**Dependencies:** AP-006, HTK-001, HTK-002

**Dependency type:** Architecture and Implementation

**Acceptance criteria:**

- [ ] The approved disclosure mechanism is operational.
- [ ] Public disclosure of secrets, state, plans, inventories, and topology is prohibited.
- [ ] Support maturity is accurate.
- [ ] Internal and external references are clickable and authoritative.
- [ ] README and documentation index link to the security policy.
- [ ] Any approved GitHub security setting is verified after configuration.

**Required validation:**

- Verify the disclosure mechanism operationally.
- Follow all links.
- Compare maturity language with the README.
- Read back applicable GitHub security settings.
- Review sensitive-data guidance.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- A placeholder or unverified disclosure mechanism must not be presented as operational.

**Destructive impact:** LOW

**Blocked by:**

- AP-006
- HTK-001
- HTK-002

**Resolution owner:** Architecture for AP-006; Roadmap for implementation dependencies

**Implementation owner:** Developer

**Unblock condition:** AP-006 is approved and HTK-001/HTK-002 are Done.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- Security, README, and navigation documentation are reconciled in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-007 — Add the pull-request template

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** Contributor and security entry points

**Objective:** Prompt authors for bounded scope, validation, documentation impact, architecture alignment, risks, and public-safety confirmation.

**Why:** The PR template operationalizes the contributor contract during review.

**Source-of-truth references:**

- HTK-005 contributor guide.
- Accepted architecture and public-safety requirements.

**Scope:**

- Request objective, scope, validation, documentation impact, architecture impact, risks, and safety confirmation.
- Require direct links to related Issues, ADRs, and reference material.
- Keep the template concise.

**Non-goals:**

- Duplicating the contributor guide.
- Requiring nonexistent checks.
- Introducing unrelated process ceremony.

**Expected repository areas:**

- GitHub pull-request template configuration.

**Dependencies:** HTK-005

**Dependency type:** Implementation

**Acceptance criteria:**

- [ ] Documentation impact is explicit.
- [ ] Architecture deviations and destructive behavior are surfaced.
- [ ] Related Issues and ADRs use direct links.
- [ ] Public-safety confirmation is included.
- [ ] The rendered template is concise and usable.

**Required validation:**

- Preview rendered Markdown.
- Follow all template links.
- Compare prompts with contributor guidance.
- Validate through an implementation PR when authorized.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Warn that raw plans, state, and logs may reveal sensitive infrastructure information.

**Destructive impact:** NONE

**Blocked by:**

- HTK-005

**Resolution owner:** Roadmap

**Implementation owner:** Developer

**Unblock condition:** HTK-005 is Done.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- Contributor documentation remains consistent in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-008 — Add focused public-safe issue templates

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** Contributor and security entry points

**Objective:** Provide bounded defect and feature-request entry points while redirecting sensitive reports.

**Why:** Structured, sanitized Issues are easier to assess without inviting private infrastructure details.

**Source-of-truth references:**

- HTK-005 contributor guide.
- HTK-006 security policy and disclosure mechanism.
- Project public-safety requirements.

**Scope:**

- Add distinct defect and feature-request templates.
- Add issue-chooser guidance for security disclosures.
- Require fictionalized or sanitized reproduction data.
- Ask feature proposals to explain reusable, environment-neutral value.
- Require direct links for referenced Issues, PRs, ADRs, and external sources.

**Non-goals:**

- A template for every technical area.
- Automatic assignment or labeling.
- Collecting real plans, state, inventories, endpoints, or topology.

**Expected repository areas:**

- GitHub Issue-template configuration.
- Linked contributor and security guidance.

**Dependencies:** HTK-005, HTK-006

**Dependency type:** Implementation

**Acceptance criteria:**

- [ ] Defect and feature templates have distinct purposes.
- [ ] Security reports use the approved disclosure mechanism rather than public Issues.
- [ ] Sensitive/private artifacts are explicitly prohibited.
- [ ] Feature requests must justify reusable public value.
- [ ] Durable references are clickable.
- [ ] Templates do not mention unavailable commands or checks.

**Required validation:**

- Validate template syntax.
- Preview templates through GitHub during the implementation PR.
- Follow every link.
- Compare guidance with contributor and security policies.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Request sanitized excerpts only; never request full plans, state, or private logs.

**Destructive impact:** NONE

**Blocked by:**

- HTK-005
- HTK-006

**Resolution owner:** Roadmap

**Implementation owner:** Developer

**Unblock condition:** HTK-005 and HTK-006 are Done.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- Contributor/security documentation remains consistent in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-009 — Apply approved GitHub repository metadata

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** GitHub repository baseline

**Objective:** Configure description, topics, homepage, and maturity wording exactly as Architecture approves.

**Why:** GitHub-side discovery and identity should agree with the README and architecture.

**Source-of-truth references:**

- AP-004 approved repository metadata.
- HTK-002 public landing page.

**Scope:**

- Apply the approved repository description and topics.
- Apply an approved homepage URL if one exists.
- Confirm Issue and PR features needed by the roadmap remain enabled.
- Reconcile metadata with README wording.

**Non-goals:**

- Inventing metadata.
- Changing repository visibility.
- Enabling unapproved security products or integrations.
- Changing merge or ruleset settings.

**Expected repository areas:**

- GitHub repository settings only.
- README only if reconciliation reveals an approved wording mismatch.

**Dependencies:** AP-004, HTK-002

**Dependency type:** Architecture and Implementation

**Acceptance criteria:**

- [ ] Description and topics match AP-004 exactly.
- [ ] Metadata does not imply unsupported maturity or capabilities.
- [ ] README and repository metadata agree.
- [ ] Any configured homepage is valid and publicly appropriate.
- [ ] Issue and PR features required by the roadmap remain enabled.
- [ ] No private account or environment metadata appears.

**Required validation:**

- Read back repository metadata through GitHub.
- Compare values with AP-004 and the README.
- Follow the homepage link if configured.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Do not expose private environments, account identifiers, or internal project URLs.

**Destructive impact:** LOW

**Blocked by:**

- AP-004
- HTK-002

**Resolution owner:** Architecture for AP-004; Roadmap for HTK-002

**Implementation owner:** Developer

**Unblock condition:** AP-004 is approved and HTK-002 is Done.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- README and repository metadata are reconciled in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

### HTK-010 — Reconcile baseline merge and ruleset configuration

**Status:** Blocked

**Milestone:** M1 — Public Project Contract

**Epic:** GitHub repository baseline

**Objective:** Apply the approved merge-method and default-branch protection policy.

**Why:** Current GitHub configuration must not be treated as intentional policy until Architecture approves the desired state.

**Source-of-truth references:**

- AP-005 approved merge and ruleset policy.
- Current active [Protect main ruleset](https://github.com/mlznlv/homelab-iac-toolkit/rules/21646346).
- HTK-005 contributor workflow.

**Scope:**

- Apply only AP-005-approved merge methods.
- Reconcile approval, thread-resolution, bypass, force-push, branch-deletion, signed-commit, and linear-history settings.
- Document effective contribution behavior.
- Leave required CI checks for M3.

**Non-goals:**

- Inventing repository policy.
- Adding required checks before stable CI exists.
- Changing visibility, ownership, or unrelated security settings.

**Expected repository areas:**

- GitHub merge settings and default-branch ruleset.
- Contributor documentation where behavior is user-visible.

**Dependencies:** AP-005, HTK-005

**Dependency type:** Architecture and Implementation

**Acceptance criteria:**

- [ ] Effective GitHub settings match AP-005 exactly.
- [ ] Force-push and branch-deletion behavior match AP-005.
- [ ] Allowed merge methods match documented contributor workflow.
- [ ] No unstable or nonexistent CI check is required.
- [ ] Settings are read back and recorded for review.
- [ ] Contributor documentation is reconciled in the same change.

**Required validation:**

- Read back repository merge settings.
- Read back the effective ruleset.
- Compare configuration with AP-005.
- Verify contributor documentation links and behavior descriptions.

**Documentation impact:** UPDATE REQUIRED

**Security/public-safety considerations:**

- Do not weaken branch protections beyond the approved policy.
- Apply changes carefully to avoid locking out all merges.

**Destructive impact:** MEDIUM

**Blocked by:**

- AP-005
- HTK-005

**Resolution owner:** Architecture for AP-005; Roadmap for HTK-005

**Implementation owner:** Developer

**Unblock condition:** AP-005 is approved and HTK-005 is Done.

**Definition of Done:**

- Implementation complete.
- Acceptance criteria satisfied.
- Required validation passes.
- Contributor documentation is reconciled in the same change.
- No unresolved architecture deviation.
- PR and applicable CI complete.

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

## Roadmap transition model

### Initial state

- `docs/roadmap.md` contains milestone-level planning and the full provisional M1 ticket definitions.
- AP-001 and AP-002 remain unresolved Architecture prerequisites.
- No M1 GitHub Milestone or implementation Issues exist.

### After Architecture persistence

- Governance accepts the committed ADRs and architecture/repository-design documentation.
- Roadmap replaces provisional AP references with direct clickable links to the accepted repository files.
- Roadmap re-evaluates ticket dependencies and readiness without changing Architecture decisions.

### When M1 execution begins

- Create the M1 GitHub Milestone.
- Create the approved M1 GitHub Issues with full ticket definitions.
- GitHub Issues become authoritative for detailed ticket execution, status, blockers, discussion, and validation evidence.
- Replace the duplicated full ticket definitions in `docs/roadmap.md` with a compact linked Issue index.

### After the transition

- `docs/roadmap.md` owns milestone-level planning, project phase, major dependencies, Architecture blockers, and deferred work.
- GitHub Issues own ticket execution and status.
- Active GitHub Milestones own near-term execution grouping.
- The repository must not maintain two competing detailed ticket stores.

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

## Final persistence and execution checklist

### A. Roadmap persistence gate

- [ ] Governance has approved the roadmap content.
- [ ] The roadmap is changed through the protected-main review workflow.
- [ ] Only roadmap-owned files are modified.
- [ ] Repository links are relative and current GitHub artifacts use direct links.
- [ ] No fabricated ADR or architecture-document paths are present.
- [ ] Public-safety validation finds no private environment data, credentials, identities, decrypted secrets, state, or sensitive plans.

### B. Architecture persistence acceptance gate

- [ ] AP-001 is committed and Governance-accepted.
- [ ] AP-002 is committed and Governance-accepted.
- [ ] Roadmap replaces provisional AP references with direct links to accepted ADRs and architecture documentation.
- [ ] Architecture changes and their roadmap impact are reconciled explicitly.

### C. M1 GitHub Milestone and Issue creation gate

- [ ] AP-001 is accepted.
- [ ] AP-002 is accepted.
- [ ] Roadmap references are reconciled.
- [ ] M1 entry criteria are satisfied and M1 is ready to begin.
- [ ] Governance authorizes M1 planning-object persistence.
- [ ] Create only the approved M1 GitHub Milestone, Issues, and minimal labels.
- [ ] Link the resulting Milestone and Issues from this roadmap.
- [ ] Replace duplicated full ticket definitions with a compact linked Issue index only after Issues become authoritative.

### D. Developer implementation handoff gate

- [ ] Exactly one highest-priority Ready Issue is selected.
- [ ] All hard dependencies are satisfied.
- [ ] Architecture references are direct links to accepted artifacts.
- [ ] Developer does not need to invent architecture or policy.
- [ ] Scope and non-goals are bounded.
- [ ] Documentation impact is explicit.
- [ ] Required validation is explicit.
- [ ] Risks and destructive impact are explicit.
- [ ] The handoff contains no unrelated future tickets.
