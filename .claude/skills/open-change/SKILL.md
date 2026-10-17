---
name: open-change
description: Open the Issue and pull request for a change in this repository, choosing the right authority for it. Use when starting work that will be committed, or when a change has no Issue yet.
disable-model-invocation: true
---

# Open a change

Use [Contributing](../../../CONTRIBUTING.md#contribution-workflow) for authority,
issue types and focused branch/PR workflow. Derive ownership from the governing
document, not a similar issue's label. Verify stated dependencies on `main`;
a PO-owned readiness transition is not yours to infer. Explicit maintainer
authorization in the session takes precedence.

Follow the [PR template](../../../.github/pull_request_template.md) and
[validation-evidence](../validation-evidence/SKILL.md). Keep the body true as the
branch changes: recheck dependencies, changed files and counts before review.

Before deleting a merged branch, check for open PRs based on it and retarget
them first; deleting their base can close them and prevent reopening.
