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
| ansible-core | `requirements-dev.txt` | Guest configuration management | [ansible-core](https://pypi.org/project/ansible-core/) |
| check-jsonschema | `requirements-dev.txt` | GitHub metadata schema validation | [check-jsonschema](https://pypi.org/project/check-jsonschema/) |
| yamllint | `requirements-dev.txt` | YAML linting | [yamllint](https://pypi.org/project/yamllint/) |

OpenTofu, Ansible, Task, SOPS, and age are declared because they are the project
technologies a contributor needs available. Reusable OpenTofu and Ansible
content, and the workflow definitions that would invoke these tools, are added
by later milestones.

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

Install the Python packages into a virtual environment:

```sh
python -m pip install --requirement requirements-dev.txt
```

Install each runtime and standalone tool at its declared version from the
upstream project listed above, or let a version manager that reads
`.tool-versions`, such as [mise](https://mise.jdx.dev/) or
[asdf](https://asdf-vm.com/), install them. A version manager is a convenience
and is not required; what matters is that the installed versions match the
declarations.

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
| ansible-core | `ansible --version` |
| check-jsonschema | `check-jsonschema --version` |
| yamllint | `yamllint --version` |

## Changing a supported version

A version change is an ordinary repository change: edit the declaration file in
a pull request, where it is reviewed like any other change.

The declarations are authoritative. The GitHub Actions workflows currently pin
several of the same versions inline and have not yet been wired to read the
declarations, so a version change must update those workflow pins in the same
pull request until they do. Consuming the declarations from continuous
integration and from a reproducible development environment is separate work.
