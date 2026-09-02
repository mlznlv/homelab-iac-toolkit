# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The project is a reusable, open-source infrastructure-as-code toolkit for Proxmox VE homelabs. This file is orientation, not authority: the documents below decide, this file points at them and must not restate their decisions. Where this file and a durable document disagree, the durable document is right and this file needs fixing.

## Authoritative documents

| For | Read |
| --- | --- |
| Project scope, maturity and navigation | [`README.md`](README.md) |
| The approved plan, milestone boundaries and what is currently blocked | [`docs/roadmap.md`](docs/roadmap.md) |
| Cross-cutting boundaries, lifecycle ownership and validation philosophy | [`docs/architecture.md`](docs/architecture.md) |
| Where content belongs and what each area of the repository owns | [`docs/repository-design.md`](docs/repository-design.md) |
| Durable decisions and their status | [`docs/decisions/README.md`](docs/decisions/README.md) |
| Supported tool versions, and how to obtain and check them | [`docs/toolchain.md`](docs/toolchain.md) |
| How a contributor sets up, validates a change and gets it reviewed | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| The repository's security posture and how a problem is reported | [`SECURITY.md`](SECURITY.md) |

Architecture is not decided in code, in a pull request, or in this file. An unresolved architectural question is raised through the workflow below and recorded in an Architecture Decision Record.

## Current state

The project is in its bootstrap, pre-release stage. The roadmap records the current phase, the active blocker and the next action; read it there rather than inferring it from the repository.

What exists today:

- **First reusable component:** [`tofu/modules/proxmox-linux-vm/`](tofu/modules/proxmox-linux-vm), the OpenTofu module accepted in [ADR 0006](docs/decisions/0006-guest-agent-channel-at-creation.md), with its own README and contract tests. The tests mock the provider, so they need no Proxmox endpoint and no credentials, and they are evidence about the module's configuration rather than about a live Proxmox VE. `task validate:tofu` runs them.
- **Project documentation:** the README and its documentation index, the roadmap, architecture, repository design, the ADR index and ADRs 0001–0006, the supported-tool-version and local-validation documentation, [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`SECURITY.md`](SECURITY.md).
- **Contribution governance:** the Issue templates and [`pull_request_template.md`](.github/pull_request_template.md) described below, plus [`dependabot.yml`](.github/dependabot.yml).
- **Declared tool versions:** [`.tool-versions`](.tool-versions) for language runtimes and standalone command-line tools, and [`requirements-dev.txt`](requirements-dev.txt) for Python packages. These declarations are authoritative for supported versions; [`docs/toolchain.md`](docs/toolchain.md) explains how to read, obtain, check and change them. [`requirements-dev.lock`](requirements-dev.lock) is generated from the Python declaration and pins the whole closure with hashes; it is what every environment installs, and it is regenerated rather than edited.
- **Validation configuration:** [`.markdownlint-cli2.yaml`](.markdownlint-cli2.yaml), [`.yamllint`](.yamllint) and [`.editorconfig`](.editorconfig).
- **Local validation:** [`docs/validation.md`](docs/validation.md) documents the direct command behind every current check, and [`Taskfile.yml`](Taskfile.yml) wraps them as discoverable entry points, with `task validate` running the whole set. Both work without the other: the direct commands need no Task, and the wrappers only invoke what the documentation shows.
- **Canonical development environment:** [`.devcontainer/`](.devcontainer) builds the supported toolchain from the declarations above, and [`docs/development-environment.md`](docs/development-environment.md) explains how to open and check it. Native development remains supported when the installed versions match.
- **Publication-safety controls:** [`.gitignore`](.gitignore), which applies to every contributor, and the optional write-time hook described below. Two checks under [`scripts/`](scripts) keep them honest: one asserts that the ignore rules and the hook agree, the other checks tracked content for ignored files and personal paths.
- **Dependency integrity:** [`scripts/check-python-lock.sh`](scripts/check-python-lock.sh) checks the generated Python lock against the declaration it comes from, so an install cannot quietly use versions the repository no longer declares. It is a dependency check rather than a publication-safety one.

  All three scripts run in both local validation and continuous integration, write nothing, and need no network access.
- **Continuous integration:** [`.github/workflows/ci.yml`](.github/workflows/ci.yml), which installs the declared toolchain and runs the same Task entry points as local validation, so the checks are defined once and enforced in both places.

What does not exist yet, and must not be written about as though it did:

- **No Ansible or example content.** There is no `ansible/` or `examples/` content. Their approved placement is in the repository design; the components themselves are outstanding work.
- **No build system, and no live-infrastructure test path.** Nothing here is built or packaged. The only component tests are the credential-free contract tests described above; no check has ever run against a Proxmox VE, and none may claim to.

Do not document a command, path or setup procedure here or anywhere else in this repository without running it first.

## Public and private repository boundary

This repository is the public half of a public/private split: reusable toolkit code is published here, while concrete environment configuration lives in a separate private deployment repository. [ADR 0001](docs/decisions/0001-public-toolkit-private-deployment-boundary.md) defines what each side owns, and [`docs/architecture.md`](docs/architecture.md) states the boundary in context. Read those for the detail; two consequences bind every change made here:

- **Everything committed must be safe to publish.** No real secrets, credentials, decryption identities, private deployment data, or generated state.
- **The toolkit must remain usable without the private deployment repository.** Nothing here may depend on an unpublished file.

Examples and documentation therefore use fictional or standards-reserved values, such as RFC 5737 addresses and RFC 2606 domain names. The file-name controls listed above are a backstop for the obvious cases, not a substitute for reading what a change actually publishes.

## Contribution workflow

Work is tracked in GitHub Issues and delivered in focused pull requests. The templates are the current definition of that process — follow the template that applies rather than improvising around it.

- **Developer implementation work** starts from a [Specification](.github/ISSUE_TEMPLATE/spec.yml) issue: an implementation-ready unit of work that cites an approved roadmap item and defines outcome, scope, out-of-scope items, acceptance criteria, dependencies and architecture alignment. Architecture is not decided there. An [Implementation task](.github/ISSUE_TEMPLATE/task.yml) issue then tracks exactly one approved specification, recording implementation and validation status rather than restating the spec, and requires that specification to be approved with no unresolved architecture decisions before work starts.
- **Architecture-owned changes** to the roadmap, architecture, repository design or ADRs use the [Architecture change](.github/ISSUE_TEMPLATE/architecture.yml) issue instead. They cite the roadmap item or Architecture document that authorizes them and do not invent an implementation specification.

A pull request cites the specification it closes or the authority it acts under, stays inside it, and introduces no secrets, private deployment data or generated state. Unrelated changes are grounds for rejection, however small and however tempting: an opportunistic ignore rule or drive-by fix belongs in its own Issue and its own pull request.

## Optional Claude Code configuration

The committed `.claude/` directory is optional, non-authoritative assistance for Claude Code sessions, as the repository design requires. It defines no project behavior and is not enforcement: repository safety and validation rest on `.gitignore`, the repository's validation configuration and CI, which apply to every contributor whatever tools they use. Removing `.claude/` must leave the repository fully usable.

- [`.claude/settings.json`](.claude/settings.json) pre-approves inspection and validation commands and registers the hook below. Its command list is limited to `git` and `gh` inspection, to tools this repository declares in `.tool-versions` or `requirements-dev.txt`, and to the repository's own validation entry points and helper scripts. An allow rule pre-authorizes every invocation it matches, which is to say Claude Code runs it without asking, and a prefix rule cannot exclude a flag. The entries name inspection and validation commands, but `markdownlint-cli2` and `zizmor` have fix modes and `git branch` can delete a branch, so those three entries pre-authorize a mutating invocation as much as the intended one. The repository's checks and review govern what lands in the repository; they do not govern what a pre-authorized command does to a working copy, and a deleted local branch is gone whatever CI later says. That is the reason to keep this list to inspection and validation commands, and to read a change to it as a permission change rather than a convenience. `.claude/` remains optional defense in depth, as the repository design describes it, rather than the layer the repository relies on: `.gitignore`, the validation configuration and CI are the controls that apply to every contributor whatever tools they use.
- [`.claude/hooks/block-unsafe-writes.sh`](.claude/hooks/block-unsafe-writes.sh) refuses to write files that must never exist in this repository. It shortens the feedback loop during a session; `.gitignore` is the control that protects the repository.
- [`.claude/agents/public-safety-reviewer.md`](.claude/agents/public-safety-reviewer.md) is a review aid for the boundary above. Its authority is ADR 0001, not the agent file.
- `.claude/settings.local.json` is personal, ignored by git, and must not be committed.
