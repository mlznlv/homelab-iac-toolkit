# Release policy

[ADR 0008](decisions/0008-first-pre-release-contract.md) explains the first-release decision.
This page owns publication gates and correction rules; commands and versions come from the
executable files at the candidate commit.

## Identity and artifacts

The first version is `v0.1.0-alpha.1`: `v` is the tag prefix, and `0.1.0-alpha.1` is the
[SemVer](https://semver.org/) identifier. Publication is an explicit maintainer operation: an
immutable tag on an already-merged `main` commit, a GitHub pre-release and GitHub-provided
source archives only. No custom artifacts, registries or automated publisher are introduced.

The release states the exact full SHA used by the [consumer
checkout](using.md#one-checkout-one-commit). Enable [GitHub release
immutability](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)
before publication. GitHub-generated provenance/attestation binds the tag, commit and assets; no
custom signing infrastructure is required.

## Maturity

This is an evaluation/early-consumer pre-release. Source identity is immutable; interfaces may
break before 1.0. There is no support-duration, maintenance-line, LTS, response-time,
release-cadence or 1.0 commitment. Later releases receive new SemVer identifiers when needed.
Release publication does not strengthen the [compatibility evidence](compatibility.md) at that
source snapshot.

## Changelog and migration

Use [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) style: `Unreleased` first,
applicable categories only, notable consumer impact rather than commit history. Record
breaking/deprecated/removed behavior and actionable migration, or explicitly state that none is
needed. The initial release has no predecessor. Use a separate migration guide only when the
procedure needs it for clarity/safety.

Date entries with the actual publication date. If publication slips after preparation merges,
correct the date through a reviewed PR, select a new candidate SHA and rerun every gate. Tagged
changelog/compatibility snapshots remain historical authority; notes summarize and link to them.
Consumers review these before changing their SHA and following the [normal
workflow](using.md#workflow). Migration must not normalize blind apply, automatic state
mutation, unattended infrastructure changes or hidden configuration rewrites.

## Candidate gate

Before drafting, record in a durable release issue:

1. One exact full SHA reachable from `main`, containing complete release docs,
   the correctly dated changelog, compatibility snapshot, maturity, upgrade and
   migration guidance, and full-SHA consumption instructions.
2. Complete repository validation from a clean checkout of that SHA, plus
   passing publication-safety and secret-history checks.
3. Passing required/applicable GitHub checks under the accepted trigger model.
   Account for every expected source of evidence; absence is not success and
   does not require inventing a new trigger solely for release status.
4. No unresolved blocking Architecture, implementation, security or release finding.
5. The target tag/release does not exist and repository immutability is enabled.

## Draft and publish

Draft against the selected SHA, mark as a pre-release and review notes before explicit
publication. Notes include version, full SHA, maturity, migration, pinned
changelog/compatibility links, validation evidence and its lack of live infrastructure/guest
proof. A commit cannot contain its own SHA; the release record provides it. Follow [GitHub's
release
workflow](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

After publication verify pre-release and immutability flags, the tag and notes' exact SHA,
snapshot links, absence of custom assets and expected GitHub provenance/attestation. Record the
release URL and final evidence in the issue.

## Corrections and security

A failed gate blocks publication. Fix through reviewed PRs, select a new source SHA and repeat
the complete gate; drafts may be edited or discarded. After publication, only
editorial/non-semantic title or note corrections may amend the record. Substantive source,
compatibility, migration or artifact corrections need a **new version**. Never move the tag,
replace/delete immutable assets, rewrite the source snapshot or delete/recreate the release.
Editorial changelog corrections on `main` leave the tagged history intact.

Maintainer publication authorization stays outside normal public CI. No release credential,
elevated write permission, privileged PR trigger or credential broker is added. Validation
remains credential-free and independent of deployments. Changing security, ownership,
validation, compatibility or distribution boundaries requires Architecture review before a new
release mechanism is implemented.
