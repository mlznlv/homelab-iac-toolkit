# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository, a reusable open-source infrastructure-as-code toolkit for Proxmox VE homelabs.

This file is orientation, not authority. The documents below decide; this file points at them and must not restate their decisions. Where they disagree, the durable document is right and this file needs fixing.

## Authoritative documents

| For | Read |
| --- | --- |
| Project scope, maturity and navigation | [`README.md`](README.md) |
| How another repository consumes the toolkit | [`docs/consuming-the-toolkit.md`](docs/consuming-the-toolkit.md) |
| The approved plan, milestone boundaries and what is currently blocked | [`docs/roadmap.md`](docs/roadmap.md) |
| Cross-cutting boundaries, lifecycle ownership and validation philosophy | [`docs/architecture.md`](docs/architecture.md) |
| Where content belongs and what each area of the repository owns | [`docs/repository-design.md`](docs/repository-design.md) |
| Durable decisions and their status | [`docs/decisions/README.md`](docs/decisions/README.md) |
| Platform targets, evidence and explicit non-claims | [`docs/compatibility.md`](docs/compatibility.md) |
| Supported tool versions, and how to obtain and check them | [`docs/toolchain.md`](docs/toolchain.md) |
| Every check, its direct command and its Task entry point | [`docs/validation.md`](docs/validation.md) |
| How a contributor sets up, validates a change and gets it reviewed | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| The repository's security posture and how a problem is reported | [`SECURITY.md`](SECURITY.md) |

Architecture is not decided in code, in a pull request, or in this file. An unresolved architectural question is raised through the workflow below and recorded in an Architecture Decision Record.

## What binds every change

The roadmap records the current phase and next action. Read it there rather than inferring it from the repository, and do not maintain an inventory of the repository here.

- **Everything committed must be safe to publish.** No real secrets, credentials, decryption identities, private deployment data, or generated state. Examples use fictional or standards-reserved values, such as RFC 5737 addresses and RFC 2606 domain names. [ADR 0001](docs/decisions/0001-public-toolkit-private-deployment-boundary.md) defines the public and private split. The file-name controls are a backstop for the obvious cases, not a substitute for reading what a change actually publishes.
- **The toolkit must remain usable without the private deployment repository.** Nothing here may depend on an unpublished file.
- **No validation here is evidence about a running system.** Every check is credential-free and structural: the module's tests mock the provider, the role's checks read its tasks, and the example is checked against a temporary stand-in checkout. Nothing has ever run against a Proxmox VE or a guest, and nothing may claim to. [Compatibility](docs/compatibility.md) records the boundary.
- **Do not document a command, path or setup procedure without running it first.**

## Contribution workflow

Work is tracked in GitHub Issues and delivered in focused pull requests. Follow the template that applies rather than improvising around it.

- **Developer implementation work** starts from a [Specification](.github/ISSUE_TEMPLATE/spec.yml) issue, which an [Implementation task](.github/ISSUE_TEMPLATE/task.yml) issue then tracks. Architecture is not decided in either.
- **Architecture-owned changes** to the roadmap, architecture, repository design or ADRs use the [Architecture change](.github/ISSUE_TEMPLATE/architecture.yml) issue, citing the authority they act under.

A pull request cites the specification it closes or the authority it acts under, stays inside it, and introduces no secrets, private deployment data or generated state. Unrelated changes are grounds for rejection, however small and however tempting: an opportunistic ignore rule or drive-by fix belongs in its own Issue and its own pull request.

## Optional Claude Code configuration

The committed `.claude/` directory is optional, non-authoritative assistance. It defines no project behavior and is not enforcement: `.gitignore`, the validation configuration and CI are the controls that apply to every contributor whatever tools they use, and removing `.claude/` must leave the repository fully usable.

[`.claude/settings.json`](.claude/settings.json) pre-approves inspection and validation commands and registers two hooks: [`hooks/block-unsafe-writes.sh`](.claude/hooks/block-unsafe-writes.sh) refuses to write files that must never exist here, and [`hooks/check-before-stopping.sh`](.claude/hooks/check-before-stopping.sh) refuses to end a turn while the working tree fails the fast local checks. The second runs nothing when no tracked file has changed, skips any check whose tool is absent, and leaves the rest of `task validate` a deliberate step.

**Read a change to that command list as a permission change, not a convenience.** An allow rule runs every invocation it matches without asking, and a prefix rule cannot exclude a flag — so `markdownlint-cli2` and `zizmor`, which have fix modes, and `git branch`, which can delete a branch, are pre-authorized in their mutating forms too. Review governs what lands in the repository, not what a pre-authorized command does to a working copy, and a deleted local branch is gone whatever CI later says.

[`.claude/skills/`](.claude/skills) holds the repository's own recurring procedures, loaded on demand rather than every session: `validation-evidence` for producing a pull request's evidence from a real run, and `open-change` for choosing the authority a change is raised under. Both point at the documents that decide rather than restating them.

[`.claude/agents/public-safety-reviewer.md`](.claude/agents/public-safety-reviewer.md) is a review aid whose authority is ADR 0001, not the agent file. `.claude/settings.local.json` is personal, ignored by git, and must not be committed.
