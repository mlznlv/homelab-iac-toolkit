# ADR 0003: Development environment and tool-version policy

Status: Accepted.

## Decision

- Use a repository-owned Dev Container as the canonical contributor environment.
- Support native development when installed tools match repository declarations.
- Keep version declarations/locks independent and authoritative, with one
  declaration per dependency class consumed by container, native setup and CI.
- Require explicit reviewed version changes and a credential-free environment
  without private inventory, personal dotfiles or privileged host mounts by default.
- Leave container base, manifest formats, installers and lock tooling as
  implementation choices that preserve these boundaries.

## Rationale

A native version manager alone cannot standardize system dependencies. Nix would
add disproportionate onboarding/maintenance cost; a container provides a
reproducible default while retaining direct native commands.

## Consequences

The project maintains the container; contributors need a compatible runtime for
that path. Native flexibility is not a compatibility promise outside supported
versions. No automatic deployment access, identities or decryption is supplied;
personal dotfiles remain outside the correctness boundary.

## References

- [Setup and declarations](../../CONTRIBUTING.md#set-up)
- [CLI consumption distinction](0016-module-cli-minimum-and-evidence-policy.md)
