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

Architecture is not decided in code, in a pull request, or in this file. An unresolved architectural question is raised through the workflow below and recorded in an Architecture Decision Record.

## Current state

The project is in its bootstrap, pre-release stage. The roadmap records the current phase, the active blocker and the next action; read it there rather than inferring it from the repository.

What exists today:

- **Project documentation:** the README, roadmap, architecture, repository design, the ADR index and ADRs 0001–0004, and the supported-tool-version documentation.
- **Contribution governance:** the Issue templates and [`pull_request_template.md`](.github/pull_request_template.md) described below, plus [`dependabot.yml`](.github/dependabot.yml).
- **Declared tool versions:** [`.tool-versions`](.tool-versions) for language runtimes and standalone command-line tools, and [`requirements-dev.txt`](requirements-dev.txt) for Python packages. These declarations are authoritative for supported versions; [`docs/toolchain.md`](docs/toolchain.md) explains how to read, obtain, check and change them.
- **Validation configuration:** [`.markdownlint-cli2.yaml`](.markdownlint-cli2.yaml), [`.yamllint`](.yamllint) and [`.editorconfig`](.editorconfig).
- **Local validation:** [`docs/validation.md`](docs/validation.md) documents the direct command behind every current check, and [`Taskfile.yml`](Taskfile.yml) wraps them as discoverable entry points, with `task validate` running the whole set. Both work without the other: the direct commands need no Task, and the wrappers only invoke what the documentation shows.
- **Canonical development environment:** [`.devcontainer/`](.devcontainer) builds the supported toolchain from the declarations above, and [`docs/development-environment.md`](docs/development-environment.md) explains how to open and check it. Native development remains supported when the installed versions match.
- **Publication-safety controls:** [`.gitignore`](.gitignore), which applies to every contributor, and the optional write-time hook described below. [`scripts/check-publication-safety-patterns.sh`](scripts/check-publication-safety-patterns.sh) asserts that the two agree; it creates no files, needs only `git` and the declared `jq`, and can be run today.
- **Continuous integration:** [`.github/workflows/ci.yml`](.github/workflows/ci.yml), which is currently the definition of what is checked on every pull request.

What does not exist yet, and must not be written about as though it did:

- **No toolkit source.** There is no `tofu/`, `ansible/` or `examples/` content. Their approved placement is in the repository design; the components themselves are later milestone work.
- **No reconciled continuous integration.** The workflow still defines its checks inline and repeats several declared tool versions rather than consuming the declarations and the local check definitions; the roadmap sequences that work. Local validation and CI therefore express the same expectations today by agreement rather than by construction, and a change to one has to be carried to the other.
- **No build system or test suite.** The commands that exist validate the repository's own content; there is nothing to build or unit-test yet.

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

- [`.claude/settings.json`](.claude/settings.json) pre-approves inspection and validation commands and registers the hook below. Its command list is limited to `git` and `gh` inspection and to tools this repository declares in `.tool-versions` or `requirements-dev.txt`; it pre-approves nothing a contributor could not run by hand, and it decides no check — the repository's validation configuration and CI do that.
- [`.claude/hooks/block-unsafe-writes.sh`](.claude/hooks/block-unsafe-writes.sh) refuses to write files that must never exist in this repository. It shortens the feedback loop during a session; `.gitignore` is the control that protects the repository.
- [`.claude/agents/public-safety-reviewer.md`](.claude/agents/public-safety-reviewer.md) is a review aid for the boundary above. Its authority is ADR 0001, not the agent file.
- `.claude/settings.local.json` is personal, ignored by git, and must not be committed.
