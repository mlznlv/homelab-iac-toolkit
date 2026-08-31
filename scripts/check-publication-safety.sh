#!/bin/bash
# Checks that this repository's tracked content is safe to publish.
#
# Two conditions are asserted. Each is expressed by a git command that answers
# through its output rather than its exit status, so neither can be used
# directly as a pass or fail check:
#
#   1. No tracked file matches this repository's public-safety ignore rules. A
#      file that is both tracked and ignored keeps being published even though
#      .gitignore states that it must not be.
#   2. No tracked content contains an absolute personal filesystem path. Such a
#      path exposes a contributor's home directory layout and is not
#      reproducible anywhere else.
#
# The checks read only this repository's tracked content. Nothing is written,
# and no network, credential, or private repository is used.
#
# Usage: scripts/check-publication-safety.sh
# Requires: git.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

status=0

tracked_ignored="$(git ls-files --cached --ignored --exclude-standard)"
if [ -n "${tracked_ignored}" ]; then
  echo "Tracked files match public-safety ignore rules:" >&2
  echo "${tracked_ignored}" >&2
  status=1
fi

if git grep -nE '/(Users|home)/[^/[:space:]]+/' -- .; then
  echo "Absolute personal filesystem path found." >&2
  status=1
fi

if [ "${status}" -eq 0 ]; then
  echo "No tracked file is ignored and no personal filesystem path is tracked."
fi

exit "${status}"
