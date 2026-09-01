#!/bin/bash
# Checks that the generated Python dependency lock still matches the
# declaration it is generated from.
#
# requirements-dev.txt is the declaration a person edits; requirements-dev.lock
# is generated from it and is what every environment installs. If the two drift
# apart, the installed packages stop matching the declared ones without anything
# saying so, so both directions are asserted:
#
# The lock names the packages it was asked for directly by putting the
# declaration in their "# via" annotation. Those, with their pinned versions,
# must be exactly the declared set, so all four ways the two can drift are
# caught: a version changed only in the declaration, a package added to it, a
# package removed from it, and a package that is present in the lock only as
# something else's dependency.
#
# It compares the two committed files and resolves nothing, so it needs no
# network access and cannot be affected by a new release appearing upstream.
#
# Usage: scripts/check-python-lock.sh
# Requires: git and awk.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

declaration=requirements-dev.txt
lock=requirements-dev.lock

status=0

# The declared pins, as `name==version`.
declared_packages() {
  awk '/^[^#[:space:]]/ && /==/ { print $1 }' "${declaration}" | sort
}

# The pins the lock attributes directly to the declaration, in the same form.
direct_packages_in_lock() {
  awk -v source="-r ${declaration}" '
    /^[a-zA-Z0-9._-]+==/ {
      pin = $1
      sub(/ *\\$/, "", pin)
      in_via = 0
    }
    /^ *# via/ { in_via = 1 }
    in_via && index($0, source) { print pin; in_via = 0 }
  ' "${lock}" | sort
}

while read -r pin; do
  [ -n "${pin}" ] || continue
  if direct_packages_in_lock | grep -qxF "${pin}"; then
    printf 'ok   %s\n' "${pin}"
  else
    printf 'FAIL %s is declared in %s but the lock does not pin it, at that version, as a direct requirement\n' \
      "${pin}" "${declaration}" >&2
    status=1
  fi
done < <(declared_packages)

while read -r pin; do
  [ -n "${pin}" ] || continue
  if declared_packages | grep -qxF "${pin}"; then
    continue
  fi
  printf 'FAIL %s is locked as a direct requirement but is not declared in %s\n' \
    "${pin}" "${declaration}" >&2
  status=1
done < <(direct_packages_in_lock)

if ! grep -qF "uv pip compile ${declaration}" "${lock}"; then
  printf 'FAIL %s does not record %s as the source it was generated from\n' \
    "${lock}" "${declaration}" >&2
  status=1
fi

if [ "${status}" -eq 0 ]; then
  echo "The lock matches the declaration."
else
  printf 'Regenerate the lock with the command in its header.\n' >&2
fi

exit "${status}"
