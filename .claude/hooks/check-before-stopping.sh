#!/bin/bash
# Runs this repository's fast local checks before a turn is allowed to end.
#
# CLAUDE.md and docs/validation.md already say that a change is validated
# before it is offered for review. That instruction is advisory: it holds when
# it is read and remembered, and the checks it names are cheap enough that
# skipping one is easy and noticing the skip is not. This makes the cheap half
# of that deterministic, so a turn that leaves the working tree failing them
# does not end quietly.
#
# It decides nothing. `task validate` remains the check set, docs/validation.md
# remains its documentation, and CI remains what actually governs a merge; this
# only refuses to let a session stop while a subset of that is already failing
# locally. Like everything under .claude/, it is optional defense in depth for
# Claude Code sessions: removing it must leave the repository fully usable, and
# every contributor is held to the same checks by CI whatever tools they use.
#
# Three limits are deliberate.
#
# It runs nothing when no tracked file has changed. Most turns answer a
# question or read code, and validating an unchanged tree would spend seconds
# per turn to prove what the previous run already proved.
#
# It runs only checks that are fast, local, and free of the Python virtual
# environment: whitespace, Markdown, and the two publication-safety scripts.
# The rest of `task validate` stays a deliberate step. The link check and the
# two provider downloads need the network, the secret scan reads all history,
# and the component checks need tools this hook cannot assume are installed.
#
# It never blocks because a tool is missing. A check whose tool is absent is
# skipped, because an incomplete toolchain is a setup problem for the
# contributor to fix, not a reason to refuse to end a turn.

input=$(cat)

# stop_hook_active is false when this hook cannot block, which is also how
# Claude Code breaks out after repeated blocks. Doing the work anyway would
# burn seconds to produce a verdict nothing can act on.
if [ "$(jq -r '.stop_hook_active // false' <<<"$input")" != "true" ]; then
  exit 0
fi

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

# Nothing tracked has changed, so there is nothing this turn could have broken.
# --quiet exits non-zero when a difference exists, which is the case to check.
if git diff --quiet HEAD 2>/dev/null; then
  exit 0
fi

failures=""

record() {
  failures="${failures}
- ${1}"
}

# Whitespace errors across every tracked file, the same comparison
# `task validate:whitespace` makes. git is always present: this hook already
# needed it to find the repository root.
empty_tree=$(git hash-object -t tree /dev/null)
if ! git diff --check "$empty_tree" HEAD >/dev/null 2>&1; then
  record 'whitespace errors in tracked content — reproduce with `task validate:whitespace`'
fi

if command -v markdownlint-cli2 >/dev/null 2>&1; then
  if ! git ls-files -z '*.md' | xargs -0 markdownlint-cli2 >/dev/null 2>&1; then
    record 'Markdown lint errors — reproduce with `task validate:markdown`'
  fi
fi

# Both scripts answer through their exit status and need only git and jq.
if [ -x scripts/check-publication-safety.sh ]; then
  if ! ./scripts/check-publication-safety.sh >/dev/null 2>&1; then
    record 'tracked content is unsafe to publish — reproduce with `task validate:public-safety`'
  fi
fi

if [ -x scripts/check-publication-safety-patterns.sh ] && command -v jq >/dev/null 2>&1; then
  if ! ./scripts/check-publication-safety-patterns.sh >/dev/null 2>&1; then
    record 'the .gitignore rules and the write-time hook disagree — reproduce with `task validate:safety-patterns`'
  fi
fi

[ -z "$failures" ] && exit 0

jq -n --arg reason "The working tree fails checks that CI also runs:
${failures}

Fix these before ending the turn. This hook runs only the fast local checks; run \`task validate\` for the whole set, which is what a pull request needs." '{
  hookSpecificOutput: {
    blockTurn: true,
    reason: $reason
  }
}'
exit 0
