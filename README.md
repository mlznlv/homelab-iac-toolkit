# Homelab IaC Toolkit

A reusable, open-source infrastructure-as-code toolkit for building and configuring [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview) homelabs with [OpenTofu](https://opentofu.org/), [Ansible](https://www.ansible.com/), [Task](https://taskfile.dev/), [SOPS](https://github.com/getsops/sops), [age](https://age-encryption.org/), and [GitHub Actions](https://github.com/features/actions).

> [!WARNING]
> This project is in its bootstrap, pre-release stage. Its architecture, public interfaces, compatibility policy, and reusable capabilities are still being established. It is not production-ready and does not currently offer stable APIs or compatibility guarantees.

## Why this project exists

Homelab infrastructure often grows from manual steps, environment-specific scripts, copied configuration, and automation with unclear ownership. That can make changes difficult to review, reproduce, validate, or recover from.

Homelab IaC Toolkit aims to provide reusable building blocks with explicit responsibilities and public interfaces. A separate deployment repository can compose those building blocks while retaining ownership of its real environment, topology, inventory, state, and secrets.

## Goals

- Reusable and composable infrastructure and configuration building blocks.
- Explicit ownership of infrastructure and configuration lifecycles.
- Reproducible, deterministic, and reviewable workflows.
- Credential-free validation that does not require a private homelab.
- Idempotent guest configuration where applicable.
- Clear public interfaces with low reliance on hidden conventions.
- Safe examples containing only fictional or reserved values.
- Stable interfaces as the project matures, with migration guidance when they change.
- Minimal modification of Proxmox hosts.
- Clear separation between reusable public code and private deployment data.

## Non-goals

This project is not:

- a complete personal homelab deployment;
- a repository for real inventory, topology, domains, addresses, sizing, or secrets;
- a universal all-in-one homelab framework;
- a replacement for Proxmox VE;
- a system that hides infrastructure changes behind opaque automation;
- a blind auto-apply system;
- a requirement to use a particular dotfiles repository;
- a mechanism for distributing secrets through dotfiles;
- a source of production-readiness or compatibility claims without evidence.

The toolkit favors small, understandable building blocks over abstractions intended to cover every possible homelab design.

## Intended users

The project is intended for homelab operators, contributors, maintainers, and separate deployment repositories that want reusable infrastructure-as-code components while retaining ownership of environment-specific configuration.

Users should expect to understand and review the infrastructure changes produced by the tools they run.

## Technology direction

- **OpenTofu** for infrastructure lifecycle management.
- **Proxmox VE** as the target virtualization platform.
- **Ansible** for guest operating-system and service configuration.
- **Task** for developer and operator workflow orchestration.
- **SOPS and age** as the encrypted-secrets interface for consuming repositories.
- **Git** as the source of truth for desired configuration.
- **GitHub Actions** for validation of the public toolkit.

This describes project direction. It does not imply that modules, roles, workflows, examples, or CI pipelines are already available. Provider choices, component contracts, supported platforms, and compatibility guarantees will be established through architecture documentation and Architecture Decision Records before implementation depends on them.

## Responsibility and lifecycle boundaries

- **OpenTofu owns infrastructure lifecycle**, including supported virtual machines, containers, disks, resource allocation, network attachments, and infrastructure dependencies.
- **Ansible owns guest configuration**, including packages, users, operating-system settings, application configuration, and services.
- **Task owns workflow orchestration**, not infrastructure state or guest configuration.
- **SOPS and age define the encrypted-secrets interface** for consuming repositories.
- **Git is the source of truth** for desired configuration.
- **GitHub Actions validates the public toolkit** without requiring a private deployment.

A lifecycle concern should have one clear owner. Tools must not silently compete for control of the same resource or configuration.

## Repository model

### Public toolkit repository

This repository is intended to contain reusable, publicly safe OpenTofu modules, Ansible roles, Task workflows, examples, documentation, validation, CI, and public configuration and secrets interfaces.

Everything committed here must be suitable for publication.

### Private deployment repository

A separate private deployment repository is expected to consume the toolkit and own real hosts, addresses, domains, topology, inventories, sizing, workloads, environment variables, OpenTofu state and backend configuration, encrypted real secrets, and concrete external dotfiles selection.

The public toolkit must never require access to that private repository. A private deployment may depend on the toolkit, but the toolkit must not depend on the deployment.

## Relationship to dotfiles

[`mlznlv/dotfiles`](https://github.com/mlznlv/dotfiles) is a separate public project for personal shell, editor, terminal, and command-line configuration. It is not part of this toolkit's infrastructure lifecycle.

Any future external-dotfiles support must be optional, generic, vendor-neutral, usable with other repositories, and unsuitable for distributing secrets. Concrete selection belongs to the consuming private deployment. This toolkit must remain usable without `mlznlv/dotfiles`.

## Safety and public repository policy

Contributions, examples, documentation, fixtures, logs, screenshots, and generated artifacts must not expose private deployment information.

Do not publish passwords, tokens, credentials, private keys, SSH private material, age identities, decrypted SOPS content, real secrets, OpenTofu state or sensitive plans, private inventories, real hostnames, domains, addresses, topology, account identifiers, private repository identifiers, personal filesystem paths, device names, or sensitive logs and screenshots.

Public examples must use fictional names and [documentation address ranges](https://www.rfc-editor.org/rfc/rfc5737), such as `example.com`, `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`.

Encrypted deployment data is still deployment data and belongs in the private repository. If sensitive material is committed, removing it later is insufficient: treat it as exposed, rotate or revoke it, and assess repository history.

## Infrastructure change philosophy

The expected OpenTofu workflow is:

```text
tofu fmt
tofu validate
tofu plan
human review
tofu apply
```

Planning and human review are deliberate safety boundaries. The project does not normalize blind apply. Potentially destructive behavior must be documented and reviewed.

## Engineering principles

The project favors small composable components; explicit inputs, outputs, dependencies, and ownership; deterministic behavior; validation; idempotency where applicable; sensible defaults; low magic; official upstream documentation; reviewable changes; backward compatibility where practical; migration guidance; minimal Proxmox host modification; and credential-free public validation.

It avoids monolithic abstractions, environment-specific hardcoding, hidden conventions, overlapping ownership, private-infrastructure dependencies in public CI, undocumented manual steps, destructive automation without review, and premature abstraction.

## Project maturity

Homelab IaC Toolkit is currently **experimental and pre-release**.

The repository is establishing its public contract, architecture, repository design, decision records, validation model, and open-source foundation. Reusable components, releases, and compatibility guarantees must not be assumed until implemented and documented. Before a stable release, public interfaces may change, but changes should remain intentional and documented.

## Planned development direction

1. Establish the public project contract.
2. Document architecture and repository design.
3. Record durable Architecture Decision Records.
4. Establish local validation workflows.
5. Add credential-free public CI.
6. Implement the first approved reusable OpenTofu and Ansible capabilities.
7. Establish consumer, compatibility, and release contracts.
8. Add optional isolated integration testing where justified.
9. Expand based on validated reusable needs.

A separate roadmap will define sequencing and implementation work. Planned work will not be presented as available before it exists.

## Documentation

Documentation is part of the product. As the project develops, it is expected to cover architecture, prerequisites, workflows, examples, separate-repository consumption, validation, compatibility, releases, upgrades, troubleshooting, security, and contribution practices. Links will be added only when those documents exist.

## Contributing

Contributions should preserve public/private boundaries, avoid sensitive data, keep lifecycle ownership explicit, include appropriate validation and documentation, use fictional values, avoid unrelated architecture changes, and disclose destructive or compatibility-sensitive behavior.

The contribution guide and workflow are still being established. Until available, treat substantial changes as design discussions first and do not assume unrecorded interfaces are stable.

## Security

Never report a vulnerability by publishing real credentials, state, inventory, sensitive plans, or environment-specific diagnostics. A dedicated security policy is planned; until published, sanitize public discussion and do not open public reports containing exploitable secrets or private infrastructure information.

If a credential or private key is exposed, revoke or rotate it immediately. Deleting the visible value does not invalidate it or remove it from Git history.

## License

Licensed under the [Apache License 2.0](LICENSE).
