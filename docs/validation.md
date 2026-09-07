# Local validation

Every check this repository enforces in continuous integration runs locally. Each has a direct command that works without Task, and a Task entry point wrapping that same command. The boundaries this works within are recorded in [ADR 0004](decisions/0004-local-validation-task-ci-security-boundary.md).

Validation is deterministic and leaves tracked content alone. It needs no Proxmox credentials, secret decryption, private inventory, or private deployment repository, and nothing it runs applies or destroys anything.

Only the component checks write at all, and never into tracked content: `tofu init` installs the declared provider into a git-ignored `.terraform/`, and the consumer-example check builds its stand-in checkout in a temporary directory and removes it. Three checks use the network — the link check, and the two that download the provider they declare.

## Prerequisites

Install the declared runtimes and command-line tools onto `PATH`, and the declared Python packages into a virtual environment at `.venv`. [Supported tool versions](toolchain.md) covers both.

```sh
python -m venv .venv
.venv/bin/python -m pip install --require-hashes --requirement requirements-dev.lock
```

The lock pins the whole dependency closure with hashes, so the install is verified rather than trusted.

The commands below name `yamllint` and `check-jsonschema` plainly, so activate the virtual environment (`. .venv/bin/activate`) or prefix those two with `.venv/bin/`. The Task wrappers resolve this themselves and need no activation: they use `.venv/bin` when the tools there actually run and otherwise take them from `PATH`. For a virtual environment kept elsewhere, pass `task validate VENV_BIN=path/to/bin`.

Run every command on this page from the repository root.

## Checks

The five groups correspond to the five continuous-integration jobs.

The file-based checks list tracked files rather than walking the directory, because a CI checkout contains exactly the tracked files while a working tree contains more — a `.venv`, caches, scratch notes. Walking would examine files CI never sees and fail locally where CI passes. One consequence: **a new file is checked only once staged**, since `git ls-files` reads the index.

### Repository hygiene

Check every tracked file for whitespace errors, comparing the empty tree against `HEAD` so the whole repository is examined rather than a working-tree diff.

```sh
git diff --check "$(git hash-object -t tree /dev/null)" HEAD
```

Check the generated Python lock still matches its declaration, so a stale lock cannot quietly install versions the repository no longer declares.

```sh
./scripts/check-python-lock.sh
```

Check that the optional Stop hook obeys the Stop contract: running on a normal stop, preventing it with exit 2 when a check on the current change fails, and standing down when a stop hook has already blocked. Each case states what the contract requires rather than what the hook happens to do, because a suite written the other way round passed while the hook did nothing. It builds a temporary repository and removes it, so it never touches this one, and reports nothing to check when `.claude/` has been removed.

```sh
./scripts/check-stop-hook.sh
```

Task entry points: `task validate:whitespace`, `task validate:python-lock`, `task validate:stop-hook`.

### Documentation

```sh
git ls-files -z '*.md' | xargs -0 markdownlint-cli2
git ls-files -z '*.md' | xargs -0 lychee --no-progress
```

The link check needs public network access.

Task entry points: `task validate:markdown`, `task validate:links`.

### GitHub configuration

```sh
git ls-files -z '*.yml' '*.yaml' '.yamllint' | xargs -0 yamllint
check-jsonschema --builtin-schema github-workflows .github/workflows/*.yml
check-jsonschema --builtin-schema dependabot .github/dependabot.yml
check-jsonschema --builtin-schema vendor.github-actions .github/actions/*/action.yml
check-jsonschema --builtin-schema vendor.taskfile Taskfile.yml
actionlint
```

Task entry points: `task validate:yaml`, `task validate:schemas`, `task validate:workflows`.

### Security

```sh
zizmor --no-online-audits .github/workflows/ .github/actions/
./scripts/check-publication-safety.sh
./scripts/check-publication-safety-patterns.sh
gitleaks git --redact --verbose .
```

Online audits are disabled, so no network access or GitHub token is needed. Secret-scan findings are redacted, so a match is reported without printing the value.

The publication-safety script wraps two git commands that answer through their output rather than their exit status:

```sh
git ls-files --cached --ignored --exclude-standard   # must print nothing
git grep -nE '/(Users|home)/[^/[:space:]]+/' -- .    # must find nothing
```

The patterns script checks that the `.gitignore` rules and the optional write-time hook still agree, against a table of fictional paths that are never created.

Task entry points: `task validate:workflow-audit`, `task validate:public-safety`, `task validate:safety-patterns`, `task validate:secrets`.

### Components

Parse the fixture play, lint the role, and check the contract it declares. The fixture lives inside the role, so the roles path is given explicitly.

```sh
ANSIBLE_ROLES_PATH=ansible/roles ansible-playbook --syntax-check \
  --inventory ansible/roles/qemu_guest_agent/tests/inventory.yml \
  ansible/roles/qemu_guest_agent/tests/role.yml
ANSIBLE_ROLES_PATH=ansible/roles ansible-lint --offline ansible/roles/qemu_guest_agent
python3 ansible/roles/qemu_guest_agent/tests/check-role-contract.py
```

ansible-lint warns that this repository's `.yamllint` does not match the settings it would choose. That is expected: YAML here is linted by the check above, with the repository's own configuration.

Format, initialise and validate the module, then run its contract tests. The lock is read only, so a provider no longer matching the committed `.terraform.lock.hcl` fails rather than being replaced silently. This step needs network access.

```sh
tofu fmt -check -recursive tofu/
tofu -chdir=tofu/modules/proxmox-linux-vm init -input=false -backend=false -lockfile=readonly
tofu -chdir=tofu/modules/proxmox-linux-vm validate
tofu -chdir=tofu/modules/proxmox-linux-vm test
```

Check that the module's `connection` output composes into ordinary Ansible inventory. Ansible reads the committed fixture back and the three published values must survive unchanged; that the output composes into exactly that document is asserted by the module's `tests/composition.tftest.hcl`.

```sh
ansible-inventory --inventory tofu/modules/proxmox-linux-vm/tests/composition-inventory.yml --list \
  | jq -e '(._meta.hostvars["fictional-vm"] == {ansible_host: "192.0.2.10", ansible_user: "fictional", ansible_port: 22})
      and (.fictional_guests.hosts == ["fictional-vm"])'
```

Check the consumer example. It points both components at a checkout it deliberately does not contain, so the script copies it to a temporary directory, links this repository in at that path, and runs the example's own tools there, printing each command. The contract check then asserts the structural claims those tools cannot make. This step needs network access.

```sh
tofu fmt -check -recursive examples/
./examples/separate-consumer-repository/tests/check-example.sh
python3 examples/separate-consumer-repository/tests/check-example-contract.py
```

The script takes its Ansible commands from `PATH`; set `PYTHON_TOOL_PREFIX=.venv/bin/` to point it at a virtual environment without activating, as the Task entry point does.

Task entry points: `task validate:ansible`, `task validate:tofu`, `task validate:composition`, `task validate:example`.

None of the above reads OpenTofu state, generates inventory, contacts Proxmox, or runs the role. It is contract evidence that the composition a consumer performs by hand is possible, not evidence that anyone has performed it. See [Compatibility](compatibility.md) for what this evidence does and does not demonstrate.

## Task entry points

[`Taskfile.yml`](../Taskfile.yml) wraps the commands above and nothing else. It prints each command before running it, declares no `sources:` or `status:`, so nothing is cached or silently skipped, and owns no infrastructure state, secret material, or lifecycle operation.

`task` lists the entry points; `task validate` runs every check in sequence, stopping at the first failure. The order is cheapest and most local first, leaving the three network checks last:

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
| 10 | `validate:stop-hook` | `scripts/check-stop-hook.sh` |
| 11 | `validate:secrets` | gitleaks |
| 12 | `validate:ansible` | `ansible-playbook --syntax-check`, ansible-lint, the role contract check |
| 13 | `validate:tofu` | `tofu fmt`, `tofu init`, `tofu validate`, `tofu test` |
| 14 | `validate:composition` | `ansible-inventory`, `jq` |
| 15 | `validate:example` | `tofu fmt`, the example's fixture check, the example contract check |
| 16 | `validate:links` | lychee |

CI invokes these same entry points, so the check set, tool versions, configuration and pass-or-fail semantics are defined once. Every check here has a CI counterpart, and the five jobs together invoke exactly what `task validate` invokes.
