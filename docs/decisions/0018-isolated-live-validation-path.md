# ADR 0018: Collect live Proxmox evidence only through an isolated, operator-run path

## Status

Accepted

## Context

Every check the repository runs is credential-free and structural. [Compatibility](../compatibility.md#current-evidence-level) lists what that evidence does not demonstrate, from clone, start, and destroy to cloud-init, SSH reachability, and Ansible convergence. M9 needs selected live evidence before broader compatibility claims are credible. [ADR 0004](0004-local-validation-task-ci-security-boundary.md) requires separate Architecture and isolation from normal public validation for any live testing, and [Architecture](../architecture.md#validation-and-live-testing-boundary) names what that design must settle first: credential custody, trusted triggers, infrastructure ownership, cleanup, failure handling, and cost.

A live path changes the repository's threat model. This decision is written against six threats:

- **Untrusted code reaching credentials or the reference network.** Anyone can open a pull request against a public repository. GitHub advises that self-hosted runners should almost never be used with one for that reason, and that environments with required reviewers, which withhold environment secrets until approval, do not isolate a job that runs on such a runner. Whatever a workflow here can reach is within reach of whoever can change that workflow.
- **Reviewed code misbehaving with credentials.** A merged change, a dependency, or a provider build can act wrongly. What it can then do is bounded only by what the credential authorizes and what its execution context can reach.
- **Destruction outside the run.** A run creates and destroys real guests. A mistake, or a cleanup that deletes by pattern, can reach guests, templates, or storage it did not create, including an operator's own workloads on shared hardware.
- **Leakage through output.** OpenTofu plans and state, and provider, cloud-init, Ansible, and Proxmox task logs, carry endpoints, node, storage, and bridge names, identifiers, addresses, and MAC addresses.
- **Unbounded or abandoned runs.** A run that hangs, is interrupted, or fails to clean up holds capacity and leaves orphans.
- **Overclaiming.** One run on one platform can be presented as general compatibility.

Proxmox's authorization model can confine a credential tightly. At pve-access-control 9.1.2, an API token with privilege separation, the default for a new token, receives the intersection of its own and its user's permissions; authentication refuses it after its expiry, and it can be revoked without disabling the user. ACL paths name individual guest identifiers, storage, and bridges down to a VLAN tag, and the ACL API checks only a path's form, so a grant can name an identifier no guest uses yet. At the qemu-server and pve-container revisions earlier ADRs use, cloning a VM needs `VM.Clone` on the template and `VM.Allocate` on the new identifier, creating a container needs `VM.Allocate` on its identifier, either may be authorized through a pool instead, and guests need `Datastore.AllocateSpace` on their storage and `SDN.Use` on their bridge or tag. Destroying a guest removes the ACL entries on its identifier. Neither toolkit module has a pool input, but both accept an explicit identifier.

These are source and documentation inspection, not an executed authorization test.

This decision operates within [ADR 0001](0001-public-toolkit-private-deployment-boundary.md), [ADR 0002](0002-lifecycle-orchestration-ownership.md), ADR 0004, and [ADR 0007](0007-single-revision-consumer-contract.md). Like publication under [ADR 0008](0008-first-pre-release-contract.md), live validation is a maintainer operation outside normal public CI.

## Decision

Collect live Proxmox and guest evidence only through an opt-in path that an operator runs outside this repository's CI, against an isolated reference environment, for a revision already merged to `main`. The path adds to credential-free validation and never replaces it; it never gates a pull request or a release and is never required of a contributor. This decision defines the path and implements none of it.

**Public validation is unchanged.** Normal validation stays the default and the only thing `task validate` and CI run, and it stays credential-free under ADR 0004. This repository holds no live credential, no GitHub environment or secret for live validation, no self-hosted runner, and no workflow, Task entry point, or script default that can reach a reference environment. No pull-request, push, schedule, or other repository event starts a live run. Task gains no live entry point, because ADR 0004 forbids it to run apply or destroy as validation.

**Operator and execution context.** An operator is a maintainer who owns a reference environment and its credentials and decides to run the path. A run executes in a context under that operator's sole control, which nobody else can trigger or change, such as a disposable container or VM. It holds no credential but the run's, has no access to the operator's other systems beyond what the run needs, and never runs code from a fork, a pull-request head, or an unmerged branch.

**Trigger and authorization.** The operator starts each run by hand, for one exact full commit SHA reachable from `main` that has passed normal CI, and names its scenarios from the accepted catalog and its budget before anything is created. Nothing is scheduled, and nothing is retried unattended. Anyone may propose a run or a scenario in an Issue; only an operator executes one. Live testing of an unmerged revision is consumer testing, outside the toolkit's evidence.

**Credential custody and least privilege.**

- Credentials are the operator's. They exist only in the execution context while the run needs them, and never appear in this repository, its CI, an Issue or pull request, a log, or an evidence record.
- Proxmox access uses an identity dedicated to live validation, through a privilege-separated API token created for the run, expiring no later than the run's time budget and cleanup allow, and revoked when the run ends, whatever its outcome, or as soon as exposure is suspected. It is never `root@pam`, a token without privilege separation, or the operator's personal or deployment identity.
- Write privileges are granted only on the run's declared guest identifiers, the designated storage, and the designated bridge and VLAN tags, with clone or read access to the designated templates. Nothing is granted on `/`, on other guests or pools, on a node's system configuration, or on storage, user, token, or permission administration. Any other privilege the pinned provider path needs is read-only and named in the implementation record. Grants made for a run are removed when it ends; Proxmox also removes a guest's identifier grants when it destroys the guest.
- Guest access uses an SSH key pair generated in the execution context for the run. Its public half is the bootstrap key; its private half never leaves the context and is destroyed with the run.
- A run uses the repository's declared toolchain and its committed provider locks, read only, with the integrity checks normal validation applies.

**Reference environment and resource ownership.**

- The reference environment is dedicated, and what a run creates in it is ephemeral. It is a PVE installation of the supported major, which may be nested, or a part of a shared installation where the authorization and network boundaries here hold. It is never an operator's deployment, and a run never reads, imports, or changes a deployment's state, roots, inventory, or guests.
- Its persistent fixtures are designated guest identifiers, storage, a bridge, and templates identified by a public image identity. Templates are read-only to a run. Guests attach only to a network the operator isolates for validation, with no route into other networks beyond what the scenarios need. That topology is the operator's: it is not published, and this decision selects none.
- Every guest a run creates is created by OpenTofu through the toolkit's components, from a root and state the run owns, at a designated identifier, with the run's random, non-secret label in its name. A run never adopts or modifies a resource it did not create.
- A run starts only when none of the identifiers it declares is in use, so anything at one afterwards belongs to that run. At most one run holds a reference environment at a time.

**Budget.** Before creating anything, a run declares the most guests, CPU cores, memory, and disk it will hold at once, its wall-clock limit, and its per-step timeouts, within limits the operator sets for the environment. A scenario set that exceeds them is refused before creation. The path requires no paid service; its cost is the operator's capacity and time.

**Cleanup, timeout, and failure.**

- Every run ends in cleanup, whether its scenarios pass, fail, or time out: OpenTofu destroys the run's root from the run's own state, and the run then confirms that every designated identifier is free.
- A step that exceeds its timeout stops the scenario and starts cleanup, which has its own bound.
- If cleanup fails or exceeds its bound, or the execution context is lost, the run has failed and the environment is quarantined. Its state and the identifiers of what remains are kept privately, and no run starts until the operator has recovered. Recovery retries OpenTofu destroy from the retained state; anything still left is removed by the operator after checking each resource against the run's own record. Under ADR 0002, the toolkit adds no automatic sweeper, pattern-based or direct-API deletion, or state rewrite.
- Nothing is retried in place. A failed apply is not re-applied to converge. A retry is a new run with a new label, started after cleanup is confirmed, that reuses nothing from the failed one.
- The toolkit does not restore a reference environment or its templates. A changed fixture has a new identity, and evidence for the old identity is not carried to it.

**Scenarios.** A scenario is admitted to the catalog only if it exercises a flow a component supports under accepted Architecture, bounds a specific non-claim in Compatibility, acts only on resources the run creates, and has defined cleanup. Unsupported transitions, such as root-filesystem shrinking, attachment retirement, or later nesting toggles, are never exercised as supported; a counterexample scenario needs an Architecture decision that names it. Replacement at the same identifier is excluded while grants are identifier-scoped, because destroying the old guest removes the grant the new one needs.

The first catalog is limited to the existing components: a VM cloned from a template, a no-op plan after apply, one supported in-place update, and destroy under the default destroy policy; the `qemu_guest_agent` role converging on that VM through its `connection` output, a second run reporting no change, and Proxmox then reporting the agent; and a container created from a template, a no-op plan after apply, one supported in-place update, and destroy. Exact steps and assertions belong to the implementation specification. Scenarios for the compositions M8 adds join only once Architecture accepts those compositions.

**Evidence and sanitization.**

- State, plans, inventories, raw logs, the SSH key, and credentials stay in the execution context. They are never attached to an Issue, pull request, or CI artifact, and are deleted once cleanup is confirmed and the record is reviewed, unless the operator's own policy keeps them privately for longer.
- The published record is built from an allowlist of fields, never by redacting raw output: the toolkit commit; each scenario and each step's outcome as passed, failed, or inconclusive; the date and durations; the OpenTofu, provider build, `ansible-core`, and Python versions; the PVE version and the versions of the Proxmox packages on the path; whether the installation is nested; the public identity and published checksum of each template; and the non-claims that remain. Endpoints, host, node, storage, bridge, pool, user, and token names, guest identifiers, addresses, MAC addresses, and any other value read from the environment are excluded rather than masked.
- A record reaches the repository only through a normal reviewed pull request that updates Compatibility and passes the publication-safety and secret checks. Where the record itself lives is set with the implementation.
- A claim reports every run of its scenarios at the same identities, failed and inconclusive runs included. A passing run is never selected from among failing ones.

**Claims.**

- A recorded passing run is runtime evidence for exactly its scenarios at the identities its record names. Compatibility records it beside the static, mocked, and exact-provider evidence, which it does not replace.
- It establishes nothing for another PVE version within the supported major, another provider build or tool version, another template or distribution, another storage or network configuration, or a consumer's environment, and nothing about reliability across runs, performance, availability, uninterrupted operation, scale, or any transition it did not exercise.
- A claim stays attached to its recorded identities. Before Compatibility extends it to a changed identity, a run at that identity is recorded.

**Implementation and change.** No harness, workflow, Task entry point, script, test, credential, or infrastructure is introduced here. Implementation needs a focused PO specification. Its harness must be public, statically checkable by normal validation without credentials, and runnable by an unrelated operator who supplies their own environment values at run time, and it must reconcile Repository design, Local validation, and Security when it merges. Changing the trigger, the isolation from public CI, credential custody, resource confinement, cleanup ownership, or what may be published requires a new ADR; execution tooling and budget values within these boundaries do not.

## Consequences

- Contributors, forks, and normal CI are unaffected, and no pull request can reach a credential or a reference environment through this repository.
- Live evidence follows merge. It cannot gate a pull request or a release, and the toolkit never live-tests a change before it merges.
- Evidence depends on an operator's availability and environment and is never continuous. Claims age as identities change, which creates requalification work rather than silently extended claims.
- Scenarios declare their guest identifiers, which both modules already accept, so confinement needs no module change. Replacement scenarios wait for a later decision, such as a pool input.
- A failed cleanup blocks further runs until a person recovers. That is deliberate: automatic deletion is the most destructive capability a live harness could hold.
- Compatibility gains a live-evidence record. Until one exists, every target keeps its current evidence level.
- PO can specify the harness, the first scenarios, the record format, and their placement from this decision.

## Alternatives considered

- **A GitHub environment with required reviewers, on GitHub-hosted runners reaching Proxmox:** rejected. Credentials would sit in the public repository's secret store, any workflow change merged to the permitted branch could use them, and the Proxmox API or a tunnel into the reference network would have to be reachable from hosted runners.
- **A self-hosted runner registered to this repository:** rejected. Pull requests can run code on it, and environment approval does not isolate it.
- **Privileged pull-request events such as `pull_request_target` or `workflow_run`:** rejected; ADR 0004 already prohibits executing untrusted code through them.
- **Scheduled or event-triggered runs:** rejected. They are unattended mutation, and they need credentials that persist between runs.
- **Live testing as a merge or release gate:** rejected. It would make deployment access mandatory for contributors and maintainers.
- **Long-lived test guests updated between runs:** rejected. Each run would start from accumulated state, and cleanup would have to judge what belongs to the run.
- **Running against an operator's own deployment:** rejected; it is unattended mutation of a private homelab and its private state.
- **Publishing redacted logs:** rejected. Redaction fails open when a value it does not anticipate appears; an allowlisted record fails closed.
- **An automatic orphan sweeper:** rejected. Deleting by name or pattern can remove what the run did not create, and it would compete with OpenTofu's ownership.
- **A pool input to confine runs:** deferred. Identifier, storage, and bridge grants already confine a run, and a module input is a separate component decision.

## Sources

- [GitHub: hardening for self-hosted runners](https://docs.github.com/en/actions/reference/security/secure-use#hardening-for-self-hosted-runners)
- [GitHub: environment secrets and required reviewers](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments#environment-secrets)
- [Proxmox VE API tokens, privilege separation, and expiry](https://github.com/proxmox/pve-docs/blob/b423460d22af888462b3d31dfff374abcfda95fa/pveum.adoc#L84-L116)
- [pve-access-control 9.1.2 refusing an expired token](https://github.com/proxmox/pve-access-control/blob/dff26b458651b4e1141ff0a41a296d2904b16228/src/PVE/AccessControl.pm#L509-L511)
- [pve-access-control 9.1.2 intersecting token and user permissions](https://github.com/proxmox/pve-access-control/blob/dff26b458651b4e1141ff0a41a296d2904b16228/src/PVE/RPCEnvironment.pm#L99-L108)
- [pve-access-control 9.1.2 ACL path grammar](https://github.com/proxmox/pve-access-control/blob/dff26b458651b4e1141ff0a41a296d2904b16228/src/PVE/AccessControl.pm#L1281-L1319), [checked by form only when an ACL is set](https://github.com/proxmox/pve-access-control/blob/dff26b458651b4e1141ff0a41a296d2904b16228/src/PVE/API2/ACL.pm#L162-L167)
- [pve-access-control 9.1.2 removing a destroyed guest's ACL entries](https://github.com/proxmox/pve-access-control/blob/dff26b458651b4e1141ff0a41a296d2904b16228/src/PVE/AccessControl.pm#L1898-L1919), called by [VM destroy](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/API2/Qemu.pm#L2864-L2872) and [container destroy](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/API2/LXC.pm#L904-L912)
- [qemu-server VM clone permissions](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/API2/Qemu.pm#L4335-L4348) and [bridge access check](https://github.com/proxmox/qemu-server/blob/14c0f871fa926e04eee090afae5d2d8670aa4a79/src/PVE/QemuServer.pm#L6415-L6428)
- [pve-container 6.1.14 container create permissions](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/API2/LXC.pm#L145-L152) and [bridge access check](https://github.com/proxmox/pve-container/blob/1c0488315a1df22a9bba635a81e7543b5ce664b7/src/PVE/LXC.pm#L1781-L1792)
- [pve-guest-common 6.0.5 `SDN.Use` on a bridge or VLAN tag](https://github.com/proxmox/pve-guest-common/blob/191c23e385e5dbed1938b2d1d322196831ef9331/src/PVE/GuestHelpers.pm#L397-L421)
