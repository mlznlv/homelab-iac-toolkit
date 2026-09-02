# Supported tool versions

This repository declares the versions of the tools used to develop and validate
it. The declarations are source-controlled and authoritative, and they are
independent of any particular development environment: a contributor working
natively can read them directly, and a reproducible environment consumes the
same values rather than defining its own.

Declared versions describe the supported development toolchain. They are not a
compatibility or support statement for a project release.

## Authoritative declarations

Each dependency class has exactly one authoritative declaration.

| Dependency class | Declaration | Format |
| --- | --- | --- |
| Language runtimes and standalone command-line tools | [`.tool-versions`](../.tool-versions) | One `<tool> <version>` pair per line |
| Python packages | [`requirements-dev.txt`](../requirements-dev.txt) | pip requirements with exact `==` pins |

[`requirements-dev.lock`](../requirements-dev.lock) is generated from that
declaration, not written by hand. It pins the full dependency closure with
SHA-256 hashes so an install can be verified, and it is what the container,
continuous integration and the documented local setup install. Change a version
in `requirements-dev.txt`, then regenerate the lock with the command recorded in
its header:

```sh
uv pip compile requirements-dev.txt --universal --generate-hashes \
  --python-version 3.13 --output-file requirements-dev.lock
```

Runtimes are declared at their supported series, such as `python 3.13`, because
the patch release is supplied by the platform that provides the runtime. Every
other tool is pinned to an exact release.

## Declared tools

| Tool | Declared in | Used for | Upstream |
| --- | --- | --- | --- |
| Python | `.tool-versions` | Runtime for the Python validation tooling | [python.org](https://www.python.org/) |
| Node.js | `.tool-versions` | Runtime for the Markdown validation tooling | [nodejs.org](https://nodejs.org/) |
| OpenTofu | `.tool-versions` | Infrastructure provisioning | [opentofu.org](https://opentofu.org/docs/intro/install/) |
| Task | `.tool-versions` | Developer workflow entry point | [taskfile.dev](https://taskfile.dev/installation/) |
| SOPS | `.tool-versions` | Secrets encryption | [getsops/sops](https://github.com/getsops/sops#download) |
| age | `.tool-versions` | Encryption used with SOPS | [FiloSottile/age](https://github.com/FiloSottile/age#installation) |
| markdownlint-cli2 | `.tool-versions` | Markdown linting | [DavidAnson/markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) |
| actionlint | `.tool-versions` | GitHub Actions workflow linting | [rhysd/actionlint](https://github.com/rhysd/actionlint) |
| gitleaks | `.tool-versions` | Secret scanning | [gitleaks/gitleaks](https://github.com/gitleaks/gitleaks) |
| lychee | `.tool-versions` | Documentation link checking | [lycheeverse/lychee](https://github.com/lycheeverse/lychee) |
| zizmor | `.tool-versions` | GitHub Actions security auditing | [zizmorcore/zizmor](https://github.com/zizmorcore/zizmor) |
| jq | `.tool-versions` | JSON handling in the publication-safety checks and the optional write-time hook | [jqlang/jq](https://github.com/jqlang/jq) |
| uv | `.tool-versions` | Regenerating the Python dependency lock | [astral-sh/uv](https://github.com/astral-sh/uv) |
| ansible-core | `requirements-dev.txt` | Guest configuration management | [ansible-core](https://pypi.org/project/ansible-core/) |
| ansible-lint | `requirements-dev.txt` | Linting this repository's Ansible content | [ansible-lint](https://pypi.org/project/ansible-lint/) |
| check-jsonschema | `requirements-dev.txt` | GitHub metadata schema validation | [check-jsonschema](https://pypi.org/project/check-jsonschema/) |
| yamllint | `requirements-dev.txt` | YAML linting | [yamllint](https://pypi.org/project/yamllint/) |

OpenTofu, Ansible, Task, SOPS, and age are declared because they are the project
technologies a contributor needs available. The `proxmox-linux-vm` module and
the `qemu_guest_agent` role are the first reusable content that uses them; the
workflow definitions that would run an infrastructure change come with the
milestone that introduces them.

## Determining a supported version

Read the declaration files. No other file in the repository defines a supported
version.

```sh
# A runtime or standalone command-line tool.
awk '$1 == "opentofu" { print $2 }' .tool-versions

# A Python package.
grep '^yamllint==' requirements-dev.txt
```

## Obtaining the supported versions

The [development environment](development-environment.md) installs all of these
from the declarations below, and is the canonical way to obtain them.

Install the Python packages into a virtual environment from the lock, so the
downloads are verified against its hashes:

```sh
python -m pip install --require-hashes --requirement requirements-dev.lock
```

Install each runtime and standalone tool at its declared version from the
upstream project listed above, or install all of them with
[mise](https://mise.jdx.dev/), which reads `.tool-versions` directly:

```sh
mise install
```

A version manager is a convenience and is not required; what matters is that the
installed versions match the declarations. Version managers differ in what they
accept: mise resolves a declared runtime series to its current patch release,
while others require an exact version and use their own tool names. Confirm the
result with the commands below whichever way the tools were installed.

## Checking installed versions

| Tool | Command |
| --- | --- |
| Python | `python --version` |
| Node.js | `node --version` |
| OpenTofu | `tofu version` |
| Task | `task --version` |
| SOPS | `sops --version` |
| age | `age --version` |
| markdownlint-cli2 | `markdownlint-cli2 --version` |
| actionlint | `actionlint -version` |
| gitleaks | `gitleaks version` |
| lychee | `lychee --version` |
| zizmor | `zizmor --version` |
| jq | `jq --version` |
| uv | `uv --version` |
| ansible-core | `ansible --version` |
| ansible-lint | `ansible-lint --version` |
| check-jsonschema | `check-jsonschema --version` |
| yamllint | `yamllint --version` |

## Changing a supported version

A version change is an ordinary repository change: edit the declaration file in
a pull request, where it is reviewed like any other change.

The declarations are authoritative, and no consumer restates them: the
development environment and the GitHub Actions workflows install from them, so
a version change takes effect everywhere once the declaration changes.

`requirements-dev.lock` is the one file that repeats a declared version, because
a lock has to name what it hashes. It is generated, not edited, so a Python
package change is made in `requirements-dev.txt` and the lock is regenerated
from it. `scripts/check-python-lock.sh` asserts that the two still agree, and
runs as part of local validation and in continuous integration, so a
regeneration that was forgotten fails the build rather than going unnoticed.
