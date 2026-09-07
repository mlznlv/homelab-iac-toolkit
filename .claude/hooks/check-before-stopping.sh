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
# Three parts of the Stop contract decide how it behaves, and getting any of
# them wrong makes the hook look like it works while doing nothing:
#
#   stop_hook_active is a recursion guard, not a capability flag. A normal stop
#   carries false; true means the agent is already continuing because a stop
#   hook blocked. Blocking again on that path is how a hook loops, so this one
#   stands down there and does its work on the normal stop.
#
#   Blocking is exit code 2, with the reason on stderr, which the hook
#   reference documents as preventing Claude from stopping. Exit 0 ends the
#   turn whatever is printed.
#
#   The subject is the change this turn made, so the comparison is the working
#   tree and index against HEAD. Comparing the empty tree against HEAD asks
#   what is committed, which is the question `task validate:whitespace` asks
#   about the whole repository and the wrong one here.
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

# The recursion guard. True means a stop hook has already blocked and the agent
# is continuing because of it; blocking again is how that becomes a loop.
if [ "$(jq -r '.stop_hook_active // false' <<<"$input" 2>/dev/null)" = "true" ]; then
  exit 0
fi

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

# A repository with no commits yet has no HEAD to compare against. Everything
# staged in one is new rather than changed, so the work below still applies,
# but the comparisons that name HEAD are skipped instead of being asked a
# question they cannot answer.
has_head=false
git rev-parse --verify --quiet HEAD >/dev/null 2>&1 && has_head=true

# Nothing tracked has changed, so there is nothing this turn could have broken.
# --quiet exits non-zero when a difference exists, which is the case to check.
if [ "$has_head" = true ] && git diff --quiet HEAD 2>/dev/null; then
  exit 0
fi

failures=""

record() {
  failures="${failures}
- ${1}"
}

# Whitespace errors in what this turn changed: the working tree and index
# against HEAD, staged or not. git is always present, since this hook already
# needed it to find the repository root.
if [ "$has_head" = true ]; then
  if ! git diff --check HEAD -- >/dev/null 2>&1; then
    record 'whitespace errors in the current change — reproduce with `git diff --check HEAD --`'
  fi
fi

# Probed by running it rather than by testing that it exists, for the reason
# Taskfile.yml gives about the Python virtual environment: a tool can be on
# PATH and still be unable to run. A mise shim resolves per directory, so it is
# discoverable everywhere and only works where the toolchain is declared.
# Reading "could not run" as "found lint errors" would block a turn over a
# setup problem, which is the one thing this hook promises not to do.
if markdownlint-cli2 --version >/dev/null 2>&1; then
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

if [ -x scripts/check-publication-safety-patterns.sh ] && jq --version >/dev/null 2>&1; then
  if ! ./scripts/check-publication-safety-patterns.sh >/dev/null 2>&1; then
    record 'the .gitignore rules and the write-time hook disagree — reproduce with `task validate:safety-patterns`'
  fi
fi

[ -z "$failures" ] && exit 0

# Exit 2 is what prevents the stop; stderr is what Claude is given to act on.
cat >&2 <<EOF
The working tree fails checks that CI also runs:
${failures}

Fix these before ending the turn. This hook runs only the fast local checks;
run \`task validate\` for the whole set, which is what a pull request needs.
EOF
exit 2
