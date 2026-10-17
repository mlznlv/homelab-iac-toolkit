# ADR 0008: First pre-release contract

Status: Accepted.

## Decision

- Publish `v0.1.0-alpha.1` as a GitHub pre-release from an already-merged `main` SHA.
- Use an immutable tag, GitHub Release and GitHub-provided source archives only;
  enable repository release immutability before publication.
- Keep the full SHA as coordinated consumer identity and state it in the release;
  the tag is the human-facing version identity.
- Make publication an explicit maintainer operation outside normal CI.
- Require a new version for substantive corrections, without stable-interface,
  maintenance, cadence, support-duration, LTS, response-time or 1.0 commitments.

## Rationale

Early consumers need a discoverable, reproducible version without overstating
maturity. Movable tags would destroy version/source correspondence. The accepted
checkout model needs no package/container/binary channel, automated publisher,
CI release credential or custom signing/attestation infrastructure.

## Consequences

The released compatibility snapshot carries only its recorded evidence. Full-SHA
consumption remains unchanged. [Release policy](../release-policy.md) owns gates,
changelog/migration requirements, draft/publication verification and correction
procedures; later versions use new SemVer identities when needed.

## References

- [Release policy](../release-policy.md)
- [Consumer revision](../using.md#one-checkout-one-commit)
- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)
- [Managing releases in a repository](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
