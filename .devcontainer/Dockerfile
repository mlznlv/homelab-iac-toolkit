# Canonical development environment for this repository.
#
# Tool versions are deliberately not declared here. `.tool-versions` and
# `requirements-dev.txt` are authoritative (see docs/toolchain.md), and this
# image installs exactly what they declare, so the container is a consumer of
# those declarations rather than a second source of truth.
#
# mise is the one exception: it is the installer that reads the declarations,
# and it is absent from its own tool registry, so it cannot be declared as a
# managed tool. It is pinned here by version and checksum instead.

FROM mcr.microsoft.com/devcontainers/base:bookworm@sha256:86165cfc170e9b2aa8df90b847127eea97b08eb9987021e6e6ec6c3a96545d7c

ARG MISE_VERSION=2026.8.15
ARG MISE_SHA256_AMD64=e3682d90f777d9e5940922169961aec2f3a61ad78f34c73ebbba34dfd2bc179c
ARG MISE_SHA256_ARM64=9c84ab84e4fc6cac8b66298ba13ab02eb630e100d86b2ab67b5bffdcb4c92c51

USER root

RUN set -eux; \
    architecture="$(dpkg --print-architecture)"; \
    case "${architecture}" in \
      amd64) mise_architecture=x64; mise_sha256="${MISE_SHA256_AMD64}" ;; \
      arm64) mise_architecture=arm64; mise_sha256="${MISE_SHA256_ARM64}" ;; \
      *) echo "Unsupported architecture: ${architecture}" >&2; exit 1 ;; \
    esac; \
    curl --fail --location --silent --show-error \
      "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-${mise_architecture}.tar.gz" \
      --output /tmp/mise.tar.gz; \
    echo "${mise_sha256}  /tmp/mise.tar.gz" | sha256sum --check; \
    tar --extract --gzip --file /tmp/mise.tar.gz --directory /tmp; \
    install -m 0755 /tmp/mise/bin/mise /usr/local/bin/mise; \
    rm -rf /tmp/mise /tmp/mise.tar.gz; \
    mise --version

# The toolchain lives under /opt rather than in the user's home directory, so
# that it is owned by the image rather than by whichever account opens it.
ENV MISE_DATA_DIR=/opt/mise
ENV MISE_TRUSTED_CONFIG_PATHS=/workspaces
ENV VIRTUAL_ENV=/opt/venv
ENV PATH=/opt/venv/bin:/opt/mise/shims:${PATH}

RUN install --directory --owner vscode --group vscode /opt/mise /opt/venv /opt/toolchain

# A login shell, which is what an editor terminal usually starts, sources
# /etc/profile and replaces PATH with the system default, dropping everything
# set above. Re-adding the toolchain here keeps it available in both shell
# kinds rather than only in the non-login ones.
RUN printf 'export PATH="%s:${PATH}"\n' /opt/venv/bin:/opt/mise/shims \
      > /etc/profile.d/10-toolchain-path.sh

USER vscode

# The declarations are copied on their own so that editing unrelated files does
# not invalidate the layer that installs the toolchain.
COPY --chown=vscode:vscode .tool-versions requirements-dev.txt /opt/toolchain/

RUN set -eux; \
    cd /opt/toolchain; \
    mise trust --yes; \
    mise install --yes; \
    mise exec -- python -m venv "${VIRTUAL_ENV}"; \
    "${VIRTUAL_ENV}"/bin/python -m pip install --no-cache-dir --disable-pip-version-check \
      --requirement requirements-dev.txt; \
    mise reshim
