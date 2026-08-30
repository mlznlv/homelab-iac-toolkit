# ADR 0004: Local validation, Task, and CI security boundary

## Status

Accepted

## Context

The repository has useful GitHub Actions validation, but the check implementation is CI-only. M2 requires reproducible local validation, transparent workflow entry points, and equivalent public CI behavior without private credentials or infrastructure.

## Decision

Repository-owned tool configuration and documented direct commands define validation behavior.

Task provides discoverable, thin wrappers for focused checks and non-mutating aggregate validation. Direct commands remain documented for troubleshooting and environments where Task is unavailable. Task must not own infrastructure state, run apply or destroy as part of validation, decrypt secrets, or hide stateful behavior.

CI uses the same check definitions, supported tool versions, configuration, and pass/fail semantics as local validation. The exact workflow composition and task names are implementation details.

Normal public CI:

- treats pull-request code as untrusted;
- requires no private deployment credentials or secrets;
- uses minimal token permissions;
- does not persist credentials unless explicitly required by an approved workflow;
- does not use privileged pull-request events to execute untrusted code;
- uses immutable references for third-party actions;
- provides verifiable integrity for downloaded executables and dependencies;
- performs no infrastructure apply, destroy, secret decryption, or live private-infrastructure operation;
- does not publish sensitive plans, state, logs, or decrypted artifacts.

Public network access may be used for dependency acquisition and public-link validation. Access to private networks, private repositories, or deployment infrastructure is prohibited in normal public CI.

Future live testing requires separate Architecture and isolation from normal public validation. Static validation must not be represented as live infrastructure evidence.

## Consequences

- Existing CI must be reconciled with shared local validation.
- Task becomes a supported contributor interface without becoming a lifecycle owner.
- CI remains suitable for forks and public contributions.
- Executable acquisition must satisfy the integrity policy.
- Normal validation remains available without Proxmox credentials or a private deployment repository.
