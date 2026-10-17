# Contributing

## Set up

The canonical environment is the [Dev Container](.devcontainer/devcontainer.json): open the
repository with **Dev Containers: Reopen in Container**. Its
[Dockerfile](.devcontainer/Dockerfile) uses a digest-pinned Debian base, non-root `vscode` user,
checksum-verified mise, and hash-verified Python dependencies.

Native development is also supported. Install the runtime and standalone-tool versions in
[`.tool-versions`](.tool-versions), directly from their upstream projects or with mise, then
install the Python lock:

```sh
mise install
python -m venv .venv
.venv/bin/python -m pip install --require-hashes --requirement requirements-dev.lock
```

`mise current` lists resolved tools; check native installations with their version commands.
Runtimes declare a supported series; standalone tools use exact releases. A version manager is
optional and may use different tool names or require an exact runtime patch. The declarations,
not the manager, decide.

| Dependency | Authoritative source |
| --- | --- |
| Runtimes and standalone tools | [`.tool-versions`](.tool-versions) |
| Direct Python packages | [`requirements-dev.txt`](requirements-dev.txt) |
| Verified Python dependency closure | [`requirements-dev.lock`](requirements-dev.lock) |
| Module consumer/provider constraints | Each module's `versions.tf` |
| Validation provider builds/hashes | Each module's `.terraform.lock.hcl` |

Change versions through a reviewed PR. For Python, edit the declaration and regenerate the lock
with the command in its header; never edit the lock by hand. The container and CI consume these
same files. Contributor pins do not change [module consumption
requirements](docs/compatibility.md#opentofu-cli-compatibility-and-evidence).

The container definition mounts only the workspace, adds no privileges, capabilities,
credentials, identities, private inventory or dotfiles, and configures no deployment access. Its
default network is controlled by the host runtime and may reach the host network: it is not a
network-isolation guarantee. Editor-provided SSH-agent forwarding or Git configuration is the
contributor's choice, outside this definition.

## Validate your change

From the repository root, stage new files so tracked-file checks include them:

```sh
task --list
task validate
```

[`Taskfile.yml`](Taskfile.yml) is the command reference: its `cmds` can also be run directly
without Task, and Task prints each invocation. It runs every check without caching and stops at
the first failure. For focused checks, use the `validate:*` entries listed by Task. CI invokes
the same definitions, tool versions, configuration and pass/fail semantics in its five jobs.

Task uses `.venv/bin` if its tools run, otherwise `PATH`. Set `VENV_BIN=path/to/bin` for a
different environment. Direct Python-tool commands need the environment activated or its `bin/`
prefix. A host virtual environment bind-mounted into a different-platform container may exist
but be unusable.

The checks cover whitespace, lock consistency, Markdown/links, YAML/schemas, workflows,
publication safety, secret history, the optional stop hook, modules, the role, inventory
composition and the consumer example. File checks use the Git index rather than walking caches
or scratch files. The whitespace task checks committed `HEAD`; also run `git diff --check` and
`git diff --cached --check` while editing.

Validation leaves tracked content unchanged. Provider initialization writes ignored
`.terraform/` directories; the example check uses a temporary checkout fixture. Provider
downloads and external links need public network access. Ansible lint's warning about this
repository's different yamllint settings is expected; the separate YAML check owns that
configuration.

Report the source revision, commands, exit results, failures and actual counts from the run. Do
not reuse old counts. Diagnose the failing check before changing anything; retry a suspected
network failure once and report it separately.
[Compatibility](docs/compatibility.md#current-evidence-level) defines what these checks
establish. Never describe them as live infrastructure validation.

### Module consumption compatibility evidence

At the exact declared minimum, check the final **unmodified** module through a fictional
consuming root with valid required inputs and nullable defaults. Copy the module's provider lock
into that root; initialize with backend access off and the lock read-only, then validate. Add
accepted/rejected cases for corrected behavior and its interactions with existing modes. Where
planning is needed, use isolated refresh-disabled exact-provider plans and fictional values.

Record source revision, CLI version and verified executable acquisition, provider build/lock,
inputs, commands, successes, failures and any scratch patching. Recheck final unmodified source:
patched diagnostics cannot establish its minimum. Full validation on the contributor pin and
separately specified older-version checks still apply. A test-runner feature's syntax
prerequisite neither raises the consumer minimum nor qualifies the whole suite on every later
CLI. This procedure introduces no permanent CI version matrix.

## Contribution workflow

Implementation starts from a [Specification](.github/ISSUE_TEMPLATE/spec.yml) and, when needed,
an [Implementation task](.github/ISSUE_TEMPLATE/task.yml). Boundary or decision changes use an
[Architecture change](.github/ISSUE_TEMPLATE/architecture.yml); execution-state and milestone
reconciliation belongs to the PO in GitHub Issues/Projects. Check dependencies and authority
before implementation; do not decide new architecture inside an implementation PR.

Use a focused branch/worktree from current `main`. A PR follows the
[template](.github/pull_request_template.md), cites its issue or explicit maintainer authority,
stays within that scope, and reports fresh validation. Unrelated fixes belong in separate
issues/PRs. Review every published value against [Security](SECURITY.md); filename controls are
only a backstop.

Optional agent guidance lives in [CLAUDE.md](CLAUDE.md); it adds no project authority.

## Documentation ownership

Each kind of information has one authoritative home. Other documents link to that home instead
of repeating its rules, tables, or validation logs.

| Information | Owner |
| --- | --- |
| Purpose, minimal quick start, navigation | `README.md` |
| Contributor setup, check procedures, contribution workflow | `CONTRIBUTING.md` |
| Publication safety and vulnerability reporting | `SECURITY.md` |
| Consumer-visible changes and migration actions | `CHANGELOG.md` |
| Cross-component consumer workflow | `docs/using.md` |
| System boundaries, dependency direction, repository ownership | `docs/architecture.md` |
| Supported targets and evidence level | `docs/compatibility.md` |
| Near-term direction | `docs/roadmap.md` |
| Current execution state, blockers, and run logs | GitHub Issues and Projects |
| Release rules | `docs/release-policy.md` |
| Reasons for durable decisions | `docs/decisions/` |
| Current interface, lifecycle, examples, limitations | Component and example READMEs |
| Commands, versions, dependency resolution | `Taskfile.yml`, executable declarations and lock files |
| Agent-only procedures | `CLAUDE.md` and `.claude/skills/` |

Keep public guides and component, role, and example READMEs reachable from the root README.
Update the owning document when a contract changes; use links for context elsewhere. Accepted
ADRs preserve decisions, not their original wording.

## Component evidence requirements

Implementation acceptance requires credential-free module/static checks and, where lifecycle is
claimed, separate evidence from the exact locked provider. Architecture acceptance can precede
finished implementation tests; it cannot turn mocked declarations into lifecycle or runtime
evidence.

| Component/change | Required contract coverage |
| --- | --- |
| VM base | Required/local validation, full clone, bootstrap/addressing, channel default/override, IP waiting disabled, both destroy settings, connection derivation |
| VLAN | Null default, boundaries/rejections, field mapping, unchanged device/resource/address/connection |
| Attachments | Empty default, ordered slots, all fields, addressless slot mapping, primary-only gateway, eight-device limit, case-insensitive declared-MAC/IP uniqueness, MAC output, unchanged primary/connection/resource and exclusions |
| DHCP | Static default preserved, conditional inputs, DHCP field without address/gateway, required DNS, host mapping/rejection in both modes, primary MAC, static-only additional attachments |
| IPv6 | Absent default, address/gateway beside both IPv4 modes, rejects invalid/dynamic forms, IPv4/IPv6 DNS, additional-attachment exclusion, unchanged connection/resource |
| LXC | Template creation rather than clone, Debian/unprivileged/start-on-boot, nesting default/override, sizing/rootfs, one static interface, explicit DNS domain mapping/validation, password-free creation-only keys, declared-value connection, exclusions |
| Role/example | Syntax/lint, package/service/module contract, consumer-owned privilege, no state coupling; one checkout, full SHA, unchanged inventory mapping, valid fictional interface values and no acquisition/backend/secret/orchestration mechanism |

Provider evidence covers every documented supported transition and destructive replacement,
preserves unrelated/primary network fields and MACs, and establishes subsequent no-change
planning using source-grounded read-back for supported VM updates. Keep unsupported
retirement/shrink/nesting counterexamples visible. LXC evidence includes creation flags, ignored
key changes versus native replacement, size-only growth, reboot distinctions, and
explicit-domain create/update/read without node fallback. Provider upgrades repeat the
applicable gates; a constraint alone is not evidence. Records distinguish executed plans,
modeled state, source inspection and live work not obtained. No permanent test mechanism is
mandated.
