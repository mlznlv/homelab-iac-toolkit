#!/bin/bash
# Checks that the optional Stop hook decides what it claims to decide.
#
# .claude/hooks/check-before-stopping.sh refuses to end a turn while the
# working tree fails the fast local checks. Three of its properties are the
# reason it is tolerable to run on every turn end, and all three are silent
# when they break: it does nothing when no tracked file has changed, it never
# blocks because a tool is missing, and it honours stop_hook_active. A hook
# that quietly stopped short of blocking would look exactly like a passing one.
#
# The cases run against a temporary repository built here, never against this
# one. Validation must leave tracked content alone, and the only honest way to
# test a blocking case is to make a check fail, which means writing a bad file
# and staging it. Doing that in a contributor's own tree would be both rude and
# unreliable.
#
# It contacts nothing, needs no credentials, and removes what it creates.
#
# Usage: scripts/check-stop-hook.sh
# Requires: git, jq. markdownlint-cli2 if present, which the tool-skipping case
# uses; that case is skipped when it is absent.

set -uo pipefail

cd "$(git rev-parse --show-toplevel)"

hook=$PWD/.claude/hooks/check-before-stopping.sh

# .claude/ is optional: removing it must leave the repository usable, so an
# absent hook is nothing to report against.
if [ ! -x "$hook" ]; then
  echo "No Stop hook at .claude/hooks/check-before-stopping.sh; nothing to check."
  exit 0
fi

checks=0
failures=0

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT

# A repository of its own, so a failing case can stage a bad file without
# touching the one being validated.
git -C "$work" init -q
git -C "$work" config user.email fictional@example.invalid
git -C "$work" config user.name Fictional
printf '# Probe\n\nA well-formed paragraph.\n' > "$work/README.md"
git -C "$work" add README.md
git -C "$work" commit -qm "probe"

# run <description> <stop_hook_active> <expected: silent|block>
run() {
  local description=$1 active=$2 expected=$3 output verdict status

  output=$(printf '{"stop_hook_active": %s}\n' "$active" \
    | (cd "$work" && bash "$hook") 2>/dev/null)

  if [ -z "$output" ]; then
    verdict=silent
  elif [ "$(jq -r '.hookSpecificOutput.blockTurn // false' <<<"$output" 2>/dev/null)" = "true" ]; then
    verdict=block
  else
    verdict=malformed
  fi

  checks=$((checks + 1))
  if [ "$verdict" = "$expected" ]; then
    status=ok
  else
    status=FAIL
    failures=$((failures + 1))
  fi

  printf '%-4s %-56s %s\n' "$status" "$description" "$verdict"
  if [ "$status" = FAIL ]; then
    printf '     expected %s\n' "$expected"
  fi
}

echo "The hook stays out of the way when there is nothing to say:"
run "inactive hook, clean tree" false silent
run "active hook, clean tree" true silent

printf '\nA second well-formed paragraph.\n' >> "$work/README.md"
git -C "$work" add README.md
run "active hook, changed tree, checks passing" true silent

echo
echo "It blocks only when a check it runs actually fails:"
# MD024 duplicate heading and MD030 list spacing: two errors markdownlint
# reports without needing configuration.
printf '# Probe\n\n#  Probe\n\n*  loose bullet\n' > "$work/README.md"
git -C "$work" add README.md

if command -v markdownlint-cli2 >/dev/null 2>&1; then
  run "active hook, changed tree, Markdown failing" true block
  run "inactive hook overrides a failing check" false silent
else
  echo "skip markdownlint-cli2 absent, so the failing and tool-skipping cases cannot run"
fi

echo
if [ "$failures" -ne 0 ]; then
  echo "${checks} checks, ${failures} failure(s)." >&2
  exit 1
fi
echo "${checks} checks, 0 failures."
