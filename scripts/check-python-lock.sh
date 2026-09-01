#!/bin/bash
# Checks that the generated Python dependency lock still matches the
# declaration it is generated from.
#
# requirements-dev.txt is the declaration a person edits; requirements-dev.lock
# is generated from it and is what every environment installs. Editing the
# declaration without regenerating the lock would leave the installed versions
# silently behind the declared ones, so this asserts that every declared pin
# appears in the lock at the same version, and that the lock still records the
# declaration as its source.
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

while read -r name version; do
  [ -n "${name}" ] || continue
  if awk -v pin="${name}==${version}" '
        $1 == pin || $1 == pin" \\" { found = 1 }
        END { exit !found }
      ' "${lock}"; then
    printf 'ok   %s==%s\n' "${name}" "${version}"
  else
    printf 'FAIL %s==%s is declared in %s but not pinned at that version in %s\n' \
      "${name}" "${version}" "${declaration}" "${lock}" >&2
    status=1
  fi
done < <(awk -F'==' '/^[^#[:space:]]/ && NF == 2 { print $1, $2 }' "${declaration}")

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
