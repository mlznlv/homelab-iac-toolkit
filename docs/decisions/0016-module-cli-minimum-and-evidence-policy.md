# ADR 0016: Separate module CLI compatibility from contributor validation

## Status

Accepted

## Context

Both OpenTofu modules declare a consumption minimum of 1.6.0. The contributor toolchain selects a separate exact CLI, and the repository's mock-provider tests use features that the consumption minimum cannot parse. These are different contracts, not competing declarations of one version.

The [investigation for #120](https://github.com/mlznlv/proxmox-iac-toolkit/issues/120#issuecomment-6233199326) tested unmodified source at `3a8553a16bcfd5a4e78957988d96f0b5fc9ab543` through fictional consuming roots. Initialization succeeded on each sampled CLI. VM validation failed on 1.6.0 and 1.9.4 because default null identifiers reach `floor()`; LXC validation passed. Both roots validated on 1.10.0 and contributor CLI 1.12.6. These are baseline checks, not full qualification of those versions or an interval between them.

[Developer correction #112](https://github.com/mlznlv/proxmox-iac-toolkit/issues/112) already owns the VM guards and other remaining primary/bootstrap validation defects. Earlier scratch-patched probes in PRs #114 and #113 are useful diagnostics but do not establish compatibility of unchanged main.

[ADR 0003](0003-development-environment-tool-version-policy.md) already separates authoritative version declarations from environment implementation. [ADR 0004](0004-local-validation-task-ci-security-boundary.md) defines credential-free local/CI parity. Neither requires every module consumer to run the contributor toolchain or the repository's test runner.

## Decision

Retain 1.6.0 as the intended consumer minimum for both modules. Do not raise it merely to accommodate a fixable validation defect or the repository's mock-test syntax. The current VM failure remains a declared-target breach, not an accepted exception or a verified compatibility claim.

Keep three boundaries explicit:

- Each module's executable `required_version` owns its consumption constraint. A declaration states the intended constraint; evidence must establish what the final source actually supports.
- The source-controlled contributor tool declaration owns normal repository validation, including the complete mock suites. The Dev Container, Task and CI consume it rather than defining another minimum.
- Test-runner prerequisites concern the tests. A mock feature's introduction establishes a syntax prerequisite, not that every later CLI can run the current suite, nor that module consumers need that feature.

Before accepting a retained-minimum compatibility claim, require fresh credential-free checks of the final corrected, unmodified module source through a consuming root at that exact minimum. Evidence includes successful initialization and validation with required fictional inputs and nullable defaults, plus focused accepted/rejected cases for the corrected behavior and its interactions with existing supported modes. Where plan-time checks are needed, isolated real-provider plans may use fictional configuration with refresh and backend access disabled; no live infrastructure or real credentials are required.

The evidence record identifies the exact source revision, CLI version and verified executable acquisition, provider build/lock, inputs and checks actually used, failures as well as successes, and any scratch modifications. A patched copy is not evidence that the final unmodified source passes. Recheck the final corrected source rather than carrying earlier diagnostic results forward.

Normal full repository validation continues on the contributor pin. Separately required older-version checks, including #112's existing obligations, are not waived. This decision selects no permanent version matrix or new validation implementation.

Sampled checks establish only the behavior exercised at their recorded identities. They do not qualify every version allowed by a constraint, future CLI versions, provider lifecycle, live Proxmox compatibility or guest behavior. Compatibility documentation must distinguish the declared target, current known failures and actual evidence.

A future consumption-floor change requires deliberate compatibility review, corresponding evidence and reconciliation of executable declarations and public documentation. It does not follow automatically from a contributor-pin update. Another ADR is needed if the durable policy changes.

## Consequences

- #112 can correct the VM while preserving the intended minimum; acceptance of this policy does not fix that defect or complete its evidence gate.
- LXC's successful baseline does not qualify all its features or make the repository's mock suite runnable on the consumption minimum.
- Module requirements remain machine-authoritative. Compatibility owns the evidence and limitations; contributor tooling documentation owns development setup; validation documentation owns check procedures.
- PO reconciles bounded follow-up after this decision merges, without a provider/CLI upgrade, new release policy or implicit CI-matrix project.
- Public validation remains non-destructive and credential-free. No lifecycle ownership, runtime evidence or production guarantee changes.

## Alternatives considered

- **Raise only the VM minimum to a newer sampled CLI:** rejected for this correction. A passing baseline on 1.10.0 is not full qualification and does not justify excluding consumers instead of fixing the assigned guards.
- **Make every consumer use the contributor pin:** rejected. It unnecessarily couples reusable consumption to repository test tooling.
- **Treat scratch-patched probes as proof of main:** rejected. The unchanged source must satisfy its own claim.
