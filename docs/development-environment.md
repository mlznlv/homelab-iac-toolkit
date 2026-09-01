# Development environment

The canonical way to work on this repository is the Dev Container defined in
[`.devcontainer/`](../.devcontainer). It exists so that a contributor gets the
supported toolchain without depending on how their own machine is configured.

The container is a consumer of the version declarations, not a second source of
truth for them: it installs exactly what [`.tool-versions`](../.tool-versions)
and [`requirements-dev.txt`](../requirements-dev.txt) declare, installed from the verified lock generated from it. See
[supported tool versions](toolchain.md) for those declarations and for the
native path.

## What the image contains

- A Debian base image, pinned by digest, running as the non-root `vscode` user.
- mise, pinned by version and verified against its published checksum, which
  reads `.tool-versions` and installs every tool declared there.
- A Python virtual environment holding the packages `requirements-dev.txt`
  declares, installed from `requirements-dev.lock` with hash verification and
  placed on `PATH` so `yamllint` and `check-jsonschema` are directly
  runnable.

Nothing else is added: no credentials, no decryption identities, no private
inventory, and no dotfiles.

## Opening it

An editor with Dev Containers support opens the definition directly; in Visual
Studio Code that is the **Dev Containers: Reopen in Container** command.

The same definition can be built and started from a terminal with the reference
CLI, which performs the same steps the editor does:

```sh
npx @devcontainers/cli up --workspace-folder .
```

To build and use the image on its own, without the Dev Containers tooling:

```sh
docker build --file .devcontainer/Dockerfile --tag homelab-iac-toolkit-dev .
docker run --rm --interactive --tty \
  --volume "$PWD:/workspaces/homelab-iac-toolkit" \
  --workdir /workspaces/homelab-iac-toolkit \
  homelab-iac-toolkit-dev bash
```

## What the definition does not do

The definition declares no mounts other than the workspace itself, no container
features, no added capabilities, and no privileged access.

Networking is ordinary: the build downloads the declared tools, and link
checking reaches public documentation sites. The container sits on the
container runtime's default network, so what it can reach is decided by that
runtime and by the host, and may well include the host's own network. Treat
its network position as equivalent to any other container running there.

The boundary is what the repository supplies, not what the network permits.
This definition ships no credentials, no endpoints or inventory, no decryption
identities, no privileged host interfaces, and no private-network
configuration. Nothing here is pointed at a deployment, and reaching one would
mean a contributor adding those things themselves.

Editors add their own conveniences outside this definition: a Dev Containers
client may forward an SSH agent or share the host Git configuration so that
commits and pushes work from inside the container. That behaviour belongs to the
client, not to this repository, and it is the contributor's choice.

## Checking the environment

Inside the container, `mise current` prints the resolved version of every tool
declared in `.tool-versions`. The per-tool version commands, and the equivalent
checks for the Python packages, are listed in
[supported tool versions](toolchain.md).

## Native development

Working natively stays supported: install the declared versions as described in
[supported tool versions](toolchain.md). The container is the canonical
environment, not the only one, and the declarations are what both paths share.
