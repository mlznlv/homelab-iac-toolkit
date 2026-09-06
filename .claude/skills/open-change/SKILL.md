---
name: open-change
description: Open the Issue and pull request for a change in this repository, choosing the right authority for it. Use when starting work that will be committed, or when a change has no Issue yet.
disable-model-invocation: true
---

# Open a change

Work is tracked in a GitHub Issue and delivered in a pull request that implements exactly one of them. [`CLAUDE.md`](../../../CLAUDE.md) and the templates under [`.github/ISSUE_TEMPLATE/`](../../../.github/ISSUE_TEMPLATE) define that process and remain the authority; this skill covers choosing between them and the errors that have needed correcting here.

## Decide what owns the change

**Derive this from the document that decides, not from what a similar Issue was labelled.** Copying a precedent's label has produced a wrong classification here: a roadmap reconciliation was raised as Architecture-owned because the previous milestone's had been, when the Issue that depended on it said in plain words that the PO owns it.

| The change | Authority | Raise as |
| --- | --- | --- |
| Implements approved work — code, tests, documentation of a shipped thing | An approved roadmap item | [Specification](../../../.github/ISSUE_TEMPLATE/spec.yml), then an [Implementation task](../../../.github/ISSUE_TEMPLATE/task.yml) if one is warranted |
| Changes a boundary, ownership, decision, or compatibility claim | The roadmap item or Architecture document that authorizes it | [Architecture change](../../../.github/ISSUE_TEMPLATE/architecture.yml) |
| Records milestone completion, current phase, readiness, or next action | The roadmap itself, and its own exit criteria as the test | An Issue stating it is PO-owned roadmap reconciliation — not an Architecture change |
| Optional contributor tooling under `.claude/` | [Contributor control plane](../../../docs/architecture.md#contributor-control-plane) | Specification, noting it introduces no authority |

If a change would alter an accepted decision, stop and raise the Architecture change first. Architecture is not decided inside an implementation pull request.

## Check the Issue is actually Ready

An Issue here carries a `Status:` line and often a blocking note naming its dependencies. Confirm each dependency is genuinely satisfied on `main` before starting — a merged pull request, a closed Issue, a document that now says what the note requires. Where the note says the PO must make a transition, that transition is theirs to authorize; ask rather than assuming it.

## Work in isolation

Branch from current `main` in its own worktree. Name the branch for the change, following the prefixes already in use: `feat/`, `docs/`, `architecture/`, `chore/`.

## Open the pull request

Follow [`pull_request_template.md`](../../../.github/pull_request_template.md). Two fields carry most of the review risk:

- **Authority** — cite the specification it closes, or the roadmap or Architecture document it acts under, and name the ownership correctly.
- **Validation** — real output from the run you just did. The `validation-evidence` skill covers that.

**Keep it to one Issue.** Unrelated changes are grounds for rejection however small, and an opportunistic fix belongs in its own Issue and pull request. If something genuinely must be folded in, say so in the body and name who authorized it.

## Keep the body true

Re-read the description before asking for re-review. Claims that were accurate when written go stale as the branch moves: a dependency that has since merged, a file no longer in the diff, a count that changed. Verify each against the current diff rather than assuming the edit took.

## Before deleting a branch

A merged pull request's branch should be deleted, remote and local. **Check first whether another open pull request is based on it** — deleting the base of an open pull request closes that pull request, and GitHub then refuses to reopen it while the base is missing. Retarget the child first.
