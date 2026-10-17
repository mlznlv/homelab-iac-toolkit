# ADR 0018: Isolated, operator-run live validation

Status: Proposed. Reconciles [PR #127](https://github.com/mlznlv/proxmox-iac-toolkit/pull/127).
Authority/acceptance remains with [#105](https://github.com/mlznlv/proxmox-iac-toolkit/issues/105),
including stable-composition/reference-environment prerequisites and Architecture/PO resolution.
This record authorizes no implementation or live run.

## Decision

- Keep live validation opt-in and outside repository CI/Task: no repository live
  credentials, environments/secrets, self-hosted runner, workflow or script default
  reaching the reference environment; no repository event, schedule or unattended retry.
  It supplements normal checks and never gates a PR/release or binds contributors.
- Have a maintainer who owns the reference environment manually select one full
  merged `main` SHA that passed CI, accepted scenarios and a budget. Run only in
  a solely operator-controlled context holding only the run credential and access
  needed by that run; never execute fork, PR-head or unmerged code with it.
- Use a dedicated identity, privilege-separated per-run expiring API token, revoked
  at end or suspected exposure, and per-run SSH keys kept in the context. Expiry
  covers at most run budget plus cleanup. Never use `root@pam`, a personal/deployment
  identity or an unseparated token. Use declared tools/read-only locks with integrity checks.
- Confine writes to declared guest IDs, designated storage/bridge/VLANs and template
  clone/read access. Grant nothing on `/`, other guests/pools, node configuration,
  storage/user/token/permission administration. Name any further required read-only
  privilege in the implementation record; remove grants when the run ends.
- Use an isolated dedicated reference environment, nested or a confined shared part,
  never a deployment. Templates are read-only/publicly identified; network routes
  are limited to scenario needs. OpenTofu creates every guest from run-owned roots/state,
  at initially free IDs with a random non-secret run label; one run holds the environment.
- Predeclare guest/CPU/memory/disk maxima, wall-clock/per-step/cleanup limits within
  operator limits; refuse oversized scenarios before creation. Always destroy from
  run state and verify IDs free. Timeout starts bounded cleanup; failed cleanup or
  lost context fails/quarantines the environment until manual recovery. No reapply,
  sweeper, pattern/API cleanup or state rewrite; a retry is a fresh run after cleanup.
- Publish only an allowlisted outcome record through reviewed PRs passing safety
  and secret checks. Raw state/plans/inventory/logs/keys/credentials stay private.
  Report every failed/inconclusive run at the same identities, not only successes;
  claims cover exact recorded scenarios/identities and require new runs when changed.

## Rationale

The threats are untrusted code reaching credentials, reviewed code misbehaving,
destruction outside a run, output leakage, abandoned capacity and overclaiming.
GitHub environment approval does not isolate self-hosted execution. Manual runs
outside CI avoid repository credential/reachability paths; short-lived scoped
credentials bound the damage even from reviewed code/dependencies.

Pinned Proxmox source permits ACLs on unused IDs and intersects token/user grants.
Clone needs template clone and target allocation permission; creation needs target
allocation, storage allocation and bridge/VLAN use. Destroy removes an ID's ACL,
so same-ID replacement is excluded. These are source findings, not authorization tests.
Allowlisting fails closed where redacting raw logs could miss a new private value.

## Consequences

The initial catalog covers VM create/no-op re-plan/one supported update/default
destroy, role convergence/second-run no-change/Proxmox agent reporting, and LXC
create/no-op re-plan/one supported update/destroy. Scenarios need supported flows,
a named Compatibility non-claim, run-owned resources and cleanup. Unsupported
shrink/retirement/nesting toggles are never tested as supported; counterexample or
same-ID replacement scenarios require a new decision. M8 scenarios need accepted compositions.

On cleanup failure retain state/resource identifiers privately. Recovery first
retries OpenTofu destroy from retained state; an operator checks each remaining
resource against the run record before manual removal. Nothing adopts/imports or
changes deployment state/roots/inventory/guests. Fixture changes get new identities;
the toolkit restores neither environment nor templates. Costs are operator capacity
and time, with no paid-service requirement.

The public record contains toolkit SHA; scenarios/step outcomes; date/durations;
OpenTofu/provider/Ansible/controller-Python and PVE/relevant-package versions;
nested status; public template identity/checksum; guest distribution/architecture/
exact release/cloud-init/init/Python; and remaining non-claims. All other environment
values, including names, IDs, addresses and MACs, are excluded rather than masked.
Raw material is deleted after confirmed cleanup/record review unless retained
privately under operator policy; private SSH keys never leave the context.

A pass establishes neither other versions/templates/storage/networks/environments
nor reliability, performance, availability, uninterrupted operation, scale or
untested transitions. Live results complement existing evidence and follow merge.
Implementation requires a focused PO spec, a public credential-free statically
checkable harness usable by an unrelated operator with runtime values, and updated
Architecture/Contributing/Security. Trigger, isolation, credentials, confinement,
cleanup or publication-boundary changes need a new ADR; tooling/budget values within
those boundaries do not. This proposal changes no current claim.

## References

- [Public validation boundary](0004-local-validation-task-ci-security-boundary.md)
- [Qualification](0017-guest-distribution-extension-and-qualification.md)

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
