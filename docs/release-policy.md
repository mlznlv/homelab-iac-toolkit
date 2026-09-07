# Release policy

## Purpose and authority

This document owns the toolkit's durable release policy, publication gates, required evidence, and correction rules. [ADR 0008](decisions/0008-first-pre-release-contract.md) records the first-release decision, while [Architecture](architecture.md#first-pre-release-contract) defines its cross-cutting boundaries.

Release policy does not duplicate validation implementation. [Local validation](validation.md), repository tooling, GitHub Actions, and source-controlled version and dependency declarations remain authoritative for exact commands, Task targets, CI job names, configuration, and executable constraints. A release candidate uses those sources as they exist at the selected commit.

## First pre-release

The first public version is `v0.1.0-alpha.1`. The `v` is the Git tag prefix; `0.1.0-alpha.1` is the [Semantic Versioning](https://semver.org/) identifier. The GitHub Release is marked as a pre-release and communicates evaluation and early-consumer maturity.

M5 publishes source only:

- one immutable Git tag targeting an already-merged commit on `main`;
- one GitHub Release; and
- the source archives GitHub provides for that release.

No custom binary, package, container, release asset, registry publication, or automated release publisher is required. Publication is an explicit maintainer operation.

The tag provides a human-facing and discoverable version identity. The exact coordinated-consumption identity remains the immutable full commit SHA under [ADR 0007](decisions/0007-single-revision-consumer-contract.md). The release notes state that SHA explicitly, and consumers record it in their own source-controlled checkout declaration. A tag is not a substitute for the consumer's full-SHA pin.

## Maturity and compatibility

`v0.1.0-alpha.1` is suitable for evaluation and early consumers. Its released source identity is immutable, but its public interfaces are not yet stable and breaking changes may occur before 1.0.

The release creates no support-duration, maintenance-line, LTS, response-time, future release-cadence, or 1.0 commitment. Later releases use new SemVer-compliant identifiers; their cadence and progression are decided only when another release requires them.

[Compatibility](compatibility.md) at the selected release commit is the authoritative compatibility snapshot. The release inherits only the targets and evidence recorded there. Executable source-controlled declarations remain authoritative for machine-consumable provider, dependency, runtime, and tool constraints. Release notes may summarize and link to compatibility information, but neither the notes nor the changelog maintains a competing compatibility table.

## Changelog and migration

M5 introduces a root `CHANGELOG.md` using a [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)-style structure. It keeps `Unreleased` at the top, uses only categories that apply, and omits empty categories. Entries describe notable consumer impact rather than reproducing commit or pull-request history.

The first published entry is `0.1.0-alpha.1` with the actual publication date. Release preparation should normally finish on the intended publication date. If publication slips to another calendar date after the preparation commit is merged, the date is corrected through a normal reviewed pull request, a new full candidate SHA is selected, and the complete publication gate is rerun. The release must not knowingly publish an incorrect historical date.

The changelog owns:

- what changed between releases;
- breaking, deprecated, and removed consumer-facing behavior; and
- concise migration actions when a change requires consumer action.

It may summarize or link to compatibility changes, but detailed targets and evidence stay in `docs/compatibility.md`. Release notes summarize and link to the matching changelog entry; they do not replace the committed changelog. The changelog in the tagged source is the immutable historical release record. Substantive facts about a published release are not silently rewritten; minor editorial corrections may be reviewed on `main` while the tagged snapshot remains unchanged.

The first release states that no migration from an earlier toolkit release exists. Every later release identifies breaking consumer-facing changes before publication, provides actionable migration guidance when consumer action is required, and explicitly states when no migration is required. A separate migration document is justified only when a procedure is too complex or risky to explain safely in the changelog.

Consumers upgrade deliberately: review the target changelog, compatibility snapshot, and migration guidance, then update the source-controlled immutable full-SHA pin. The toolkit does not update consumer checkouts, state, inventories, provider constraints, or configuration. Infrastructure changes continue to require `tofu plan`, human review, and explicit `tofu apply`; migration guidance must not normalize blind apply, automatic state mutation, unattended infrastructure changes, or hidden configuration rewrites.

## Immutability and correction

[GitHub immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) must be enabled for the repository before the first release is published. Once published:

- the associated tag is locked to its commit and cannot be moved;
- release assets cannot be replaced or deleted;
- the source and tag identity is therefore immutable; and
- the release title and release notes remain editable.

GitHub's generated release provenance and attestation provide supply-chain evidence binding the tag, commit SHA, and release assets. M5 does not add custom signing, attestation infrastructure, or binary provenance work.

Editorial or non-semantic release-note corrections are permitted after publication. A substantive source, compatibility, migration, or artifact correction requires a new version. Never repair a published release by moving its tag, replacing immutable content, rewriting the released source snapshot, or deleting and recreating the release.

## Release-candidate gate

Before drafting the release:

1. Merge all release content to `main`; never select an unmerged pull-request branch.
2. Select one exact immutable full commit SHA reachable from `main`.
3. Confirm that the selected source contains the complete M5 release documentation, including the correctly dated changelog entry, compatibility snapshot, maturity and upgrade guidance, initial-release migration statement, and full-SHA consumption instructions.
4. Run the complete repository validation from a clean checkout of that exact source tree.
5. Confirm that all required or otherwise applicable GitHub checks produced for that candidate under the accepted CI trigger model pass.
6. Confirm that publication-safety validation and secret scanning pass.
7. Confirm that no unresolved blocking Architecture, implementation, security, or release finding applies to the candidate.
8. Confirm that the `v0.1.0-alpha.1` tag and release do not already exist.
9. Confirm that repository release immutability is enabled.

Applicable GitHub checks are those the repository's accepted trigger model produces for that kind of commit. This policy does not require a new trigger or check solely to manufacture release status, but absence is not silently treated as success: the maintainer must account for every expected source of evidence.

The durable M5 completion record identifies:

- the exact release-candidate SHA;
- the clean-checkout repository-validation result;
- the applicable GitHub CI evidence;
- the publication-safety result; and
- the secret-scan result.

Exact commands, target names, jobs, versions, and configurations are resolved from their authoritative source-controlled files at the candidate commit rather than copied into this policy.

## Draft, review, and publication

Create a draft GitHub Release targeting the selected full SHA, not a moving branch. Mark it as a pre-release, attach no custom artifacts, and finish review of the notes before publishing. GitHub recommends drafting before publication when release immutability is enabled; see [Managing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

The release notes identify:

- `v0.1.0-alpha.1`;
- the exact full release SHA;
- evaluation and early-consumer maturity;
- that this is the initial release and no migration from an earlier toolkit release exists;
- links pinned to the released snapshots of `CHANGELOG.md` and `docs/compatibility.md`;
- the validation evidence; and
- that credential-free static and mocked validation does not prove live Proxmox provisioning, cloud-init, SSH connectivity, Ansible convergence, guest-agent runtime behavior, lifecycle operations, or compatibility with a consumer's live environment.

A source commit cannot contain its own final commit SHA. Committed documentation therefore defines the full-SHA consumption policy, while the draft and published GitHub Release record the concrete release SHA. The immutable tag and GitHub-generated provenance and attestation bind the discoverable version to that source, and consumers copy the full SHA into their own source-controlled declaration.

After the explicit maintainer publication, verify that:

- the release is marked as a pre-release;
- immutability is active for the published release;
- `v0.1.0-alpha.1` resolves to the selected full SHA;
- the notes state exactly that SHA;
- changelog and compatibility links resolve to the released snapshot;
- no custom release assets were added; and
- GitHub-generated provenance and attestation identify the expected release identity and source.

Record the release URL and the final evidence in the M5 completion record.

## Failure policy

Before publication, any failed gate blocks the release. Corrections use normal reviewed pull requests, every corrected source tree produces a new candidate SHA, and the complete gate runs again. Draft releases may be edited or discarded before publication.

After publication, only editorial or non-semantic release-note corrections may amend the existing release record. Substantive corrections follow the new-version policy above.

## Security boundary

Release publication uses maintainer GitHub authorization outside normal public CI. Normal CI receives no release credential or elevated write permission. M5 introduces no automatic publisher, privileged pull-request trigger, credential broker, registry, custom artifact pipeline, signing system, or attestation infrastructure.

Release validation remains credential-free, non-destructive, and independent of private repositories and live Proxmox infrastructure. It performs no infrastructure apply or destroy, secret decryption, or live environment test. A future release mechanism that changes these security, ownership, validation, compatibility, or distribution boundaries requires Architecture review before implementation.
