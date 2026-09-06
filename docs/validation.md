# Local validation

Every validation expectation this repository enforces in continuous integration
can be run locally. Each check has a direct command that works without Task, and
a Task entry point that wraps that same command.

This page is the operational reference. The boundaries it works within — local
and CI parity, and the limits on what Task may own — are recorded in
[ADR 0004](decisions/0004-local-validation-task-ci-security-boundary.md) and are
not restated here.

## What validation does and does not do

Validation is deterministic and leaves tracked content alone. It reads this
repository's own files and needs no Proxmox credentials, secret decryption,
private inventory, or access to a private deployment repository. No check
contacts Proxmox, and none applies or destroys anything.

The component checks are the only ones that write anything at all, and neither
writes into tracked content. `tofu init` installs the declared provider into a
`.terraform/` directory inside the module, which git ignores, and the module's
contract tests plan against a mocked provider, which creates nothing. The
consumer-example check builds its stand-in toolkit checkout in a temporary
directory and removes it when it finishes.

Three checks use the network. The link check resolves the public URLs found in
this repository's Markdown, and the component and consumer-example checks
download the provider they declare.

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

The five groups below correspond to the five continuous-integration jobs.

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

### Components

Parse a minimal fictional play that uses the Ansible role, the way a consumer's
play would use it. The fixture play lives inside the role, so the roles path is
given explicitly; nothing connects to the inventory's host, which is reserved
by RFC 2606 and resolves nowhere.

```sh
ANSIBLE_ROLES_PATH=ansible/roles ansible-playbook --syntax-check \
  --inventory ansible/roles/qemu_guest_agent/tests/inventory.yml \
  ansible/roles/qemu_guest_agent/tests/role.yml
```

Lint the role and that fixture. `--offline` keeps the check from reaching for
collections, which the role does not need.

```sh
ANSIBLE_ROLES_PATH=ansible/roles ansible-lint --offline ansible/roles/qemu_guest_agent
```

ansible-lint warns that this repository's `.yamllint` does not match the
settings it would choose. That is expected and does not affect the result: YAML
in this repository is linted by the check above, with the repository's own
configuration.

Check that the role still declares the package and service contract it
documents, and the boundaries it keeps. It reads every task and handler file
the role can execute and walks tasks nested in `block`, `rescue` and `always`.
Anything that would run content it has not read fails it: an include resolving
outside the role, a module named indirectly, another role pulled in, or a role
dependency in `meta`. It contacts no guest, needs no credential, and runs
nothing.

```sh
python3 ansible/roles/qemu_guest_agent/tests/check-role-contract.py
```

Task entry point for the three above: `task validate:ansible`.

Check the formatting of every OpenTofu file. `tofu fmt` understands the test
files too, so they are covered by the same command.

```sh
tofu fmt -check -recursive tofu/
```

Install the provider the module declares and validate the module statically.
The lock file is read only, so a provider that no longer matches the committed
`.terraform.lock.hcl` fails the check instead of being replaced silently. There
is no backend to configure: the module declares none, because a consumer owns
that. This is the step that needs network access.

```sh
tofu -chdir=tofu/modules/proxmox-linux-vm init -input=false -backend=false -lockfile=readonly
tofu -chdir=tofu/modules/proxmox-linux-vm validate
```

Run the module's contract tests. They mock the provider, so they contact no
Proxmox endpoint, need no credentials, and create nothing. What they prove, and
what they deliberately do not, is described in the module's
[README](../tofu/modules/proxmox-linux-vm/README.md).

```sh
tofu -chdir=tofu/modules/proxmox-linux-vm test
```

Task entry point: `task validate:tofu`.

Check that the module's `connection` output composes into ordinary Ansible
inventory. Ansible reads the committed fixture back and the three published
values must survive unchanged; the other half of this evidence — that the
output composes into exactly that document — is asserted by the module's
`tests/composition.tftest.hcl`, which the check above runs.

```sh
ansible-inventory --inventory tofu/modules/proxmox-linux-vm/tests/composition-inventory.yml --list \
  | jq -e '(._meta.hostvars["fictional-vm"] == {ansible_host: "192.0.2.10", ansible_user: "fictional", ansible_port: 22})
      and (.fictional_guests.hosts == ["fictional-vm"])'
```

Nothing here reads OpenTofu state, generates inventory, contacts Proxmox, or
runs the role. It is contract evidence that the composition a consumer performs
by hand is possible, not evidence that anyone has performed it.

Task entry point: `task validate:composition`.

Check the formatting of the consumer example's OpenTofu files.

```sh
tofu fmt -check -recursive examples/
```

Run the example's own tools against a stand-in toolkit checkout. The example
points both components at `vendor/homelab-iac-toolkit/`, a checkout a consumer
establishes and this repository deliberately does not contain, so the script
copies the example into a temporary directory, links this repository in at that
path, and runs the commands there. It prints each one before running it and
writes nothing into the working tree. This step needs network access, for the
provider install.

```sh
./examples/separate-consumer-repository/tests/check-example.sh
```

It takes its Ansible commands from `PATH`, so activate the virtual environment
first as above. To point it at one without activating, set
`PYTHON_TOOL_PREFIX=.venv/bin/`, which is what the Task entry point does.

The commands it runs inside that fixture are `tofu init -lockfile=readonly`,
`tofu validate` and `tofu test` in the example's OpenTofu root, then
`ansible-playbook --syntax-check`, `ansible-lint --offline` and
`ansible-inventory --list` in its Ansible directory. Together they establish
that the example parses, that its module call type-checks against the module's
real interface, that its committed inventory is the `connection` output mapped
by hand, and that its play resolves the role from the same checkout. The
provider is mocked or unconfigured throughout: no credential is read, and no
Proxmox endpoint or guest is contacted.

Check the structural claims those tools cannot make: that the pinned revision
is one immutable full commit SHA, that the OpenTofu module source and the
Ansible `roles_path` resolve into the same represented checkout, that the
inventory maps all three connection fields, and that the example carries no
acquisition, orchestration, state-reading, inventory-generation, or
secret-handling mechanism and no real address or host.

```sh
python3 examples/separate-consumer-repository/tests/check-example-contract.py
```

Task entry point for the three above: `task validate:example`.

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
The order is cheapest and most local first, which leaves the three checks that
need network access until last:

| Order | Task | Wraps |
| --- | --- | --- |
| 1 | `validate:whitespace` | `git diff --check` |
| 2 | `validate:python-lock` | `scripts/check-python-lock.sh` |
| 3 | `validate:markdown` | markdownlint-cli2 |
| 4 | `validate:yaml` | yamllint |
| 5 | `validate:schemas` | check-jsonschema |
| 6 | `validate:workflows` | actionlint |
| 7 | `validate:workflow-audit` | zizmor |
| 8 | `validate:public-safety` | `scripts/check-publication-safety.sh` |
| 9 | `validate:safety-patterns` | `scripts/check-publication-safety-patterns.sh` |
| 10 | `validate:secrets` | gitleaks |
| 11 | `validate:ansible` | `ansible-playbook --syntax-check`, ansible-lint, the role contract check |
| 12 | `validate:tofu` | `tofu fmt`, `tofu init`, `tofu validate`, `tofu test` |
| 13 | `validate:composition` | `ansible-inventory`, `jq` |
| 14 | `validate:example` | `tofu fmt`, the example's fixture check, the example contract check |
| 15 | `validate:links` | lychee |

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
counterpart, and the five CI jobs together invoke exactly the checks
`task validate` invokes.
