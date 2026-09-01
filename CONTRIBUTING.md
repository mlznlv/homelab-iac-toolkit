# Contributing

Thank you for looking at this project. It is a public toolkit in its bootstrap
stage, so the process below is small and deliberate rather than elaborate.

This page tells you where to start and what a change is expected to look like.
It points at the documents that decide things rather than restating them, so
where this page and a linked document disagree, the document is right.

## Set up

The canonical environment is the repository's Dev Container, which contains the
supported toolchain already: see
[development environment](docs/development-environment.md).

Working natively is supported too. Install the declared versions as described in
[supported tool versions](docs/toolchain.md), which is also where you look up
what a supported version currently is.

## Validate your change

Every check can be run locally, and continuous integration runs the same ones.
Run them all with:

```sh
task validate
```

[Local validation](docs/validation.md) lists each check, the direct command
behind it that you can run without Task, and what it is for.

## How work is tracked

Changes start from an issue, and a pull request implements exactly one of them:

- Implementation work starts from a
  [specification](.github/ISSUE_TEMPLATE/spec.yml) issue, which an
  [implementation task](.github/ISSUE_TEMPLATE/task.yml) issue then tracks.
- Changes to the roadmap, architecture, repository design or decision records
  use the [architecture change](.github/ISSUE_TEMPLATE/architecture.yml) issue
  instead. Architecture is not decided inside an implementation pull request.

A pull request links the issue it closes, stays inside it, and says which checks
were run. Unrelated changes are asked to move to their own pull request, however
small and however convenient it would be to include them, because a reviewer can
only approve what the linked issue describes.

## What must not be published here

This repository is the public half of a public/private split: reusable toolkit
code is published here, while concrete environment configuration belongs to a
separate private deployment repository. The boundary is defined in
[ADR 0001](docs/decisions/0001-public-toolkit-private-deployment-boundary.md)
and has one consequence for every change: everything committed must be safe to
publish. No credentials, secrets, decryption identities, private deployment
data or generated state, and examples use fictional or standards-reserved
values.

`.gitignore` and the publication-safety checks are a backstop for the obvious
cases, not a substitute for looking at what a change publishes.
[Security](SECURITY.md) describes the repository's security posture and how to
report a problem.
