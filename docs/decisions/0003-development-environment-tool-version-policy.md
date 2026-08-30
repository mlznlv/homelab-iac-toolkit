# ADR 0003: Development environment and tool-version policy

## Status

Proposed

## Context

M2 requires contributors and CI to use predictable tools without depending on personal host configuration. The stack spans operating-system packages, standalone CLIs, Python tooling, and repository linters.

A native-only version manager cannot fully standardize system dependencies. Nix would provide strong reproducibility but introduce a substantial new contributor and maintenance model. A Dev Container provides a clean, reproducible default while preserving a direct native path.

## Decision

### Canonical development environment

A repository-owned Dev Container is the canonical contributor environment.

Native development is supported as an optional path when installed tools match the repository's supported versions. Differences outside those versions are not project compatibility guarantees.

The canonical environment includes no credentials, secrets, private inventory, personal dotfiles, or private deployment configuration. It does not mount contributor identities, credentials, or privileged host interfaces by default.

### Authoritative version declarations

Source-controlled version declarations and dependency locks are authoritative for supported tool versions. The Dev Container is a consumer of those declarations, not their sole source of truth.

Each dependency class has one authoritative declaration. The container, native setup documentation, and CI consume the same declarations where applicable. Version changes are explicit, reviewable repository changes.

### Implementation details

M2 implementation selects the concrete container base, version-manifest formats, installation mechanism, and dependency-locking tools. Those choices must preserve the separation between the canonical environment and authoritative version declarations and must not duplicate conflicting version sources.

The development environment does not automatically provide credentials or connectivity for apply, secret decryption, or live infrastructure testing.

## Consequences

- Contributors need a Dev Container-compatible runtime for the canonical path.
- The project assumes maintenance responsibility for the container definition.
- Native users retain flexibility but must match supported versions.
- Version updates become explicit and reviewable.
- Personal environment and dotfiles repositories remain outside the project's correctness boundary.

## Alternatives considered

- **Native version manager as the canonical environment:** lower container overhead, but weaker operating-system reproducibility and host isolation.
- **Nix development environment:** strong reproducibility, but disproportionate onboarding and maintenance cost for M2.
- **Container-only development:** rejected because documented direct commands and compatible native workflows remain useful.
