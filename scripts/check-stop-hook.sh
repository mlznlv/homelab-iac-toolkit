#!/bin/bash
# Checks that the optional Stop hook obeys the Stop contract.
#
# .claude/hooks/check-before-stopping.sh refuses to end a turn while the
# working tree fails the fast local checks. An earlier version of this script
# asserted the hook against the implementation rather than the contract, and
# passed while the hook did nothing on a normal stop: it drove the hook with
# stop_hook_active reversed and looked for a JSON field that does not block.
# Every case below therefore states what the contract requires, and the
# verdict is the exit status the contract defines.
#
#   Exit 2 prevents the stop. Exit 0 ends the turn whatever is printed, so a
#   hook that objects on stdout and exits 0 has not objected at all.
#
#   stop_hook_active is a recursion guard. A normal stop carries false; true
#   means the agent is already continuing because a stop hook blocked. A hook
#   that works only when it is true never runs in ordinary use, which is
#   exactly the defect this file failed to catch before.
#
# The cases run against a temporary repository built here, never against this
# one. Validation must leave tracked content alone, and the only honest way to
# test a blocking case is to make a check fail, which means writing a bad file.
# Doing that in a contributor's own tree would be both rude and unreliable.
#
# It contacts nothing, needs no credentials, and removes what it creates.
#
# Usage: scripts/check-stop-hook.sh
# Requires: git, jq. markdownlint-cli2 where it can run, which one case needs;
# that case is skipped otherwise.

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

# A fixture repository has to resolve the declared toolchain the way a real one
# does. A mise shim reads .tool-versions from the directory it runs in, so a
# fixture without it leaves markdownlint-cli2 on PATH and unable to run, which
# is how the documented direct command failed on the native path while passing
# under Task.
declare_toolchain() {
  [ -f .tool-versions ] && cp .tool-versions "$1/"
}

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT

git -C "$work" init -q
git -C "$work" config user.email fictional@example.invalid
git -C "$work" config user.name Fictional
declare_toolchain "$work"
printf '# Probe\n\nA well-formed paragraph.\n' > "$work/README.md"
git -C "$work" add README.md
git -C "$work" commit -qm "probe"

# A PATH that can still run the hook but cannot run markdownlint-cli2, so a
# case can ask what a missing tool does rather than assuming. The system
# directories supply the shell utilities the hook itself uses; the stub carries
# the declared tools that live outside them. Anything not linked here is
# absent, which is the point.
stub=$work/bin
mkdir -p "$stub"
for tool in git jq; do
  ln -sf "$(command -v "$tool")" "$stub/$tool"
done
without_markdownlint=$stub:/usr/bin:/bin

# A markdownlint-cli2 that is on PATH and cannot run, which is what a mise shim
# is outside a directory declaring the toolchain. Testing that a tool exists
# rather than probing it reads this failure as lint errors.
broken=$work/broken
mkdir -p "$broken"
printf '#!/bin/sh\nexit 1\n' > "$broken/markdownlint-cli2"
chmod +x "$broken/markdownlint-cli2"
with_broken_markdownlint=$broken:$stub:/usr/bin:/bin

# run <description> <stop_hook_active> <expected: allow|block> [dir] [path]
#
# allow is exit 0, which lets the turn end. block is exit 2, which prevents it.
# Any other status is a hook that failed rather than decided, and is reported
# as such instead of being read as one of the two.
run() {
  local description=$1 active=$2 expected=$3 dir=${4:-$work} path=${5:-$PATH}
  local status verdict result

  printf '{"stop_hook_active": %s}\n' "$active" \
    | (cd "$dir" && PATH="$path" bash "$hook") >/dev/null 2>&1
  status=$?

  case "$status" in
    0) verdict=allow ;;
    2) verdict=block ;;
    *) verdict="error(exit $status)" ;;
  esac

  checks=$((checks + 1))
  if [ "$verdict" = "$expected" ]; then
    result=ok
  else
    result=FAIL
    failures=$((failures + 1))
  fi

  printf '%-4s %-58s %s\n' "$result" "$description" "$verdict"
  if [ "$result" = FAIL ]; then
    printf '     expected %s\n' "$expected"
  fi
}

echo "A normal stop carries stop_hook_active false, and is when the hook works:"
run "clean tree, normal stop" false allow

printf '\nA second well-formed paragraph.\n' >> "$work/README.md"
git -C "$work" add README.md
run "changed tree whose checks pass, normal stop" false allow

echo
echo "It prevents the stop with exit 2 when a check fails:"
# A trailing space, in the change rather than in what is committed: the error
# the whitespace check exists to catch, which an earlier version reported as
# clean because it compared the empty tree against HEAD.
#
# Deliberately not a Markdown file. Trailing whitespace in one trips
# markdownlint too, so a .md fixture here would pass whether or not the
# whitespace check works, and this case would prove nothing.
printf 'trailing space here   \n' > "$work/notes.txt"
git -C "$work" add notes.txt
run "whitespace error in the current change" false block
git -C "$work" rm -q --cached notes.txt
rm -f "$work/notes.txt"

printf '# Probe\n\n#  Probe\n\n*  loose bullet\n' > "$work/README.md"
git -C "$work" add README.md
if markdownlint-cli2 --version >/dev/null 2>&1; then
  run "Markdown lint errors in the current change" false block
else
  echo "skip markdownlint-cli2 cannot run here, so the Markdown case cannot run"
fi

echo
echo "stop_hook_active true means a stop hook has already blocked:"
# Blocking again here is how a hook loops. The content is still failing, so a
# hook that reads this flag as a capability rather than a guard blocks, and a
# hook that reads it correctly stands down.
run "already continuing, so it stands down despite the failure" true allow

echo
echo "A missing tool is a setup problem, not a reason to refuse to end a turn:"
run "the failing check's tool is absent" false allow "$work" "$without_markdownlint"
run "the tool is present but cannot run" false allow "$work" "$with_broken_markdownlint"

echo
echo "A repository with no commits has no HEAD to compare against:"
fresh=$(mktemp -d)
git -C "$fresh" init -q
declare_toolchain "$fresh"
printf '# Fresh\n\nA well-formed paragraph.\n' > "$fresh/README.md"
git -C "$fresh" add README.md
run "no commits yet, staged content well formed" false allow "$fresh"
rm -rf "$fresh"

echo
if [ "$failures" -ne 0 ]; then
  echo "${checks} checks, ${failures} failure(s)." >&2
  exit 1
fi
echo "${checks} checks, 0 failures."
