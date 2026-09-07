# ADR 0008: First pre-release contract

## Status

Accepted

## Context

M5 requires one immutable, documented pre-release that early consumers can identify and reproduce without converting the toolkit's existing pre-release interfaces into stable guarantees. The release model must preserve the coordinated full-SHA consumer contract and the credential-free public-validation boundary.

This decision operates within the accepted [public toolkit and private deployment boundary](0001-public-toolkit-private-deployment-boundary.md), [lifecycle and orchestration ownership](0002-lifecycle-orchestration-ownership.md), [local validation, Task, and CI security boundary](0004-local-validation-task-ci-security-boundary.md), and [single-revision consumer contract](0007-single-revision-consumer-contract.md).

## Decision

Adopt `v0.1.0-alpha.1` as the first toolkit version. Publish it as a GitHub pre-release from one already-merged commit on `main`, using an immutable tag and GitHub Release with only GitHub-provided source archives.

Repository release immutability must be enabled before publication. The published tag is locked to its selected commit and is never moved to repair or update the release. Substantive corrections require a new version.

The release tag is the human-facing and discoverable version identity. The exact coordinated-consumption identity remains the immutable full commit SHA required by ADR 0007. The GitHub Release states that SHA explicitly, and consumers continue to record the full SHA in their source-controlled checkout declaration for both toolkit components.

The release is an evaluation and early-consumer pre-release. It creates no stable-interface, support-duration, maintenance-line, release-cadence, LTS, response-time, or 1.0 commitment.

Publication remains an explicit maintainer operation outside normal public CI. M5 adds no custom artifact, registry publication, automated release publisher, release credential in CI, custom signing system, or attestation infrastructure.

The detailed maturity, changelog, migration, compatibility, candidate, evidence, publication, verification, and correction requirements live in [Release policy](../release-policy.md). Executable validation and version details remain in their existing authoritative sources rather than becoming part of this ADR.

## Consequences

- Early consumers can map one discoverable pre-release version to one immutable source revision.
- The release does not weaken or replace ADR 0007's full-SHA coordinated-consumption contract.
- The compatibility document at the release commit becomes that release's authoritative compatibility snapshot without expanding its evidence.
- Publication can be performed without giving normal public CI credentials or elevated permissions.
- A substantive post-publication correction requires another SemVer-compliant version.
- Future cadence, stable guarantees, registries, custom artifacts, automated publishing, signing, and broader provenance infrastructure remain deferred.

## Alternatives considered

- **Use the tag instead of a full SHA in the coordinated consumer contract:** rejected because the release identity should not replace ADR 0007's exact source-controlled revision boundary.
- **Use a movable convenience tag:** rejected because it would make the published source identity mutable and prevent reliable version-to-source mapping.
- **Publish packages, containers, binaries, or custom release assets:** rejected because M5 distributes source and the accepted consumer workflow needs no additional artifact channel.
- **Publish automatically from normal CI:** rejected because the first release does not justify release credentials, elevated permissions, or a privileged publication path in public validation.
- **Claim stable interfaces or a maintenance line:** rejected because the available evidence supports an evaluation pre-release, not long-term compatibility or support guarantees.

## Sources

- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)
- [Managing releases in a repository](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
