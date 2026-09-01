# Local validation

Every validation expectation this repository enforces in continuous integration
can be run locally. Each check has a direct command that works without Task, and
a Task entry point that wraps that same command.

This page is the operational reference. The boundaries it works within — local
and CI parity, and the limits on what Task may own — are recorded in
[ADR 0004](decisions/0004-local-validation-task-ci-security-boundary.md) and are
not restated here.

## What validation does and does not do

Validation is deterministic and non-mutating. It reads this repository's own
content, writes nothing, and needs no Proxmox credentials, secret decryption,
private inventory, or access to a private deployment repository. No check
performs an infrastructure plan, apply, or destroy.

The link check is the only check that uses the network, and only to resolve the
public URLs found in this repository's Markdown.

## Prerequisites

Install the declared runtimes and standalone command-line tools so they are on
`PATH`, and install the declared Python packages into a virtual environment at
`.venv`. Both sets of versions, and the ways to obtain them, are described in
[supported tool versions](toolchain.md).

```sh
python -m venv .venv
.venv/bin/python -m pip install --require-hashes --requirement requirements-dev.lock
```

The lock is generated from `requirements-dev.txt` and pins the whole dependency
closure with hashes, so the install is verified rather than trusted; see
[supported tool versions](toolchain.md) for how it is regenerated.

An environment that already provides the declared packages on `PATH` needs
none of that, and the commands on this page are written for both cases: they
name `yamllint` and `check-jsonschema` plainly. When the packages come from a
virtual environment, put it on `PATH` first, either by activating it:

```sh
. .venv/bin/activate
```

or by prefixing those two commands with `.venv/bin/`.

The Task wrappers do that resolution themselves, so `task validate` needs no
activation in either case. They use `.venv/bin` when the tools there run, and
otherwise take them from `PATH`; a printed command of bare `yamllint` means it
came from `PATH`. Each candidate is probed by running it rather than by testing
that the file exists, because a virtual environment built on one platform and
then used from another is present and executable yet fails at use. If neither
source provides a working tool, the task stops with the setup instruction above
rather than a command-not-found error. For a virtual environment kept somewhere
else, override the Task variable: `task validate VENV_BIN=path/to/bin`.

Run every command on this page from the repository root. `.venv/` is ignored by
git and is never committed.

## Checks

The four groups below correspond to the four continuous-integration jobs.

### Repository hygiene

Check every tracked file for whitespace errors, comparing the empty tree against
`HEAD` so the whole repository is examined rather than a working-tree diff.

```sh
git diff --check "$(git hash-object -t tree /dev/null)" HEAD
```

Task entry point: `task validate:whitespace`.

Check that the generated Python dependency lock still matches the declaration
it comes from. The packages the lock records as directly required, and their
versions, must be exactly the declared ones, so a version change, an addition
or a removal cannot be installed from a stale lock.

```sh
./scripts/check-python-lock.sh
```

Task entry point: `task validate:python-lock`.

### Documentation

Lint the Markdown, using the repository's `.markdownlint-cli2.yaml`
configuration.

```sh
git ls-files -z '*.md' | xargs -0 markdownlint-cli2
```

Task entry point: `task validate:markdown`.

Resolve every link the Markdown contains. This check needs public network
access.

```sh
git ls-files -z '*.md' | xargs -0 lychee --no-progress
```

Task entry point: `task validate:links`.

### GitHub configuration

Lint the YAML, using the repository's `.yamllint` configuration. The pathspec
covers the file names yamllint selects by default: the two YAML suffixes and its
own configuration file.

```sh
git ls-files -z '*.yml' '*.yaml' '.yamllint' | xargs -0 yamllint
```

Task entry point: `task validate:yaml`.

Validate the repository's GitHub metadata and its Taskfile against their
published schemas.

```sh
check-jsonschema --builtin-schema github-workflows .github/workflows/*.yml
check-jsonschema --builtin-schema dependabot .github/dependabot.yml
check-jsonschema --builtin-schema vendor.github-actions .github/actions/*/action.yml
check-jsonschema --builtin-schema vendor.taskfile Taskfile.yml
```

Task entry point: `task validate:schemas`.

Lint the GitHub Actions workflows.

```sh
actionlint
```

Task entry point: `task validate:workflows`.

### Security

Audit the GitHub Actions workflows for security problems. Online audits are
disabled so the check needs no network access and no GitHub token.

```sh
zizmor --no-online-audits .github/workflows/ .github/actions/
```

Task entry point: `task validate:workflow-audit`.

Check that tracked content is safe to publish. Both underlying git commands
answer through their output rather than their exit status, so
[`scripts/check-publication-safety.sh`](../scripts/check-publication-safety.sh)
turns them into a pass or fail result:

```sh
git ls-files --cached --ignored --exclude-standard   # must print nothing
git grep -nE '/(Users|home)/[^/[:space:]]+/' -- .    # must find nothing
```

```sh
./scripts/check-publication-safety.sh
```

Task entry point: `task validate:public-safety`.

Check that the repository's two publication-safety file controls — the
`.gitignore` rules and the optional Claude Code write-time hook — still agree,
using a table of fictional paths that are never created.

```sh
./scripts/check-publication-safety-patterns.sh
```

Task entry point: `task validate:safety-patterns`.

Scan the repository history for secrets. Findings are redacted, so a match is
reported without printing the matched value.

```sh
gitleaks git --redact --verbose .
```

Task entry point: `task validate:secrets`.

## Task entry points

[`Taskfile.yml`](../Taskfile.yml) wraps the commands above and nothing else. It
prints each command before running it, declares no `sources:` or `status:`, so
no result is cached and no check is silently skipped, and owns no infrastructure
state, secret material, or lifecycle operation.

List the entry points:

```sh
task
```

Run every check:

```sh
task validate
```

`task validate` runs the focused checks in sequence and stops at the first
failure, so its exit status is non-zero whenever any constituent check fails.
The order is cheapest and most local first, which leaves the slowest check and
the only one needing network access until last:

| Order | Task | Wraps |
| --- | --- | --- |
| 1 | `validate:whitespace` | `git diff --check` |
| 2 | `validate:markdown` | markdownlint-cli2 |
| 3 | `validate:yaml` | yamllint |
| 4 | `validate:schemas` | check-jsonschema |
| 5 | `validate:workflows` | actionlint |
| 6 | `validate:workflow-audit` | zizmor |
| 7 | `validate:public-safety` | `scripts/check-publication-safety.sh` |
| 8 | `validate:safety-patterns` | `scripts/check-publication-safety-patterns.sh` |
| 9 | `validate:secrets` | gitleaks |
| 10 | `validate:links` | lychee |

Task is a convenience. Every check remains runnable as the direct command shown
above, which is what to use when Task is unavailable or when a failure needs to
be reproduced in isolation.

## Why the file-based checks list tracked files

A continuous-integration checkout contains exactly the repository's tracked
files. A contributor's working tree usually contains more: a `.venv` directory,
tool caches, scratch notes, and other untracked or ignored files. A check that
walks the working directory therefore examines files that CI never sees, and
fails locally where CI passes.

Listing tracked files with `git ls-files` restores the equivalence, because the
resulting file set is the one CI would check. The difference is not theoretical:
with a `.venv` present, `yamllint .` fails on YAML shipped inside an installed
dependency, and `markdownlint-cli2 "**/*.md"` lints the Markdown files that same
directory contains.

`git ls-files` reads the index, so a newly created file is checked once it has
been staged with `git add`. That matches CI, which only ever sees committed
files.

`git ls-files -z` and `xargs -0` are used together so that the file list is
NUL-separated and file names containing spaces or newlines are passed through
unchanged.

## Relationship to continuous integration

The CI workflow runs these checks by invoking the same Task entry points, so
the check set, tool versions, repository-owned configuration and pass or fail
semantics are shared rather than restated. Every check on this page has a CI
counterpart, and the four CI jobs together invoke exactly the checks
`task validate` invokes.
