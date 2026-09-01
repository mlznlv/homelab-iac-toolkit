# Homelab IaC Toolkit

A reusable, open-source infrastructure-as-code toolkit for Proxmox VE homelabs. It is intended to provide public building blocks that can be composed by a separate, private deployment repository.

## Why

Homelab automation often combines reusable code with environment-specific configuration, making it difficult to share safely or reuse elsewhere.

This project separates the reusable toolkit from the concrete deployment. The goal is to make homelab infrastructure easier to reproduce, review, validate, and maintain without publishing private environment data.

## Goals

- Provide reusable infrastructure and configuration building blocks.
- Make homelab environments easier to reproduce and maintain.
- Make infrastructure changes easier to understand and review.
- Keep reusable public code separate from private deployments.

## Technology

The project currently focuses on:

- [OpenTofu](https://opentofu.org/)
- [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview)
- [Ansible](https://www.ansible.com/)
- [Task](https://taskfile.dev/)
- [SOPS](https://github.com/getsops/sops)
- [age](https://age-encryption.org/)
- [GitHub Actions](https://github.com/features/actions)

## Repository model

This public repository will contain reusable toolkit components, documentation, examples, and validation.

A separate private deployment repository will contain concrete environment configuration. The public toolkit must remain usable without access to private deployment data.

Everything in this repository must be safe to publish and must not contain real secrets or private deployment data.

## Status

The project is currently in its bootstrap, pre-release stage.

## Documentation

| Document | What it covers |
| --- | --- |
| [Contributing](CONTRIBUTING.md) | How to set up, validate a change, and get it reviewed |
| [Security](SECURITY.md) | Security posture of this repository and how to report a problem |
| [Development environment](docs/development-environment.md) | The canonical container, and what it deliberately omits |
| [Supported tool versions](docs/toolchain.md) | The declared versions, and how to obtain and check them |
| [Local validation](docs/validation.md) | Every check, its direct command, and its Task entry point |
| [Roadmap](docs/roadmap.md) | The approved plan and current milestone |
| [Architecture](docs/architecture.md) | Cross-cutting boundaries and lifecycle ownership |
| [Repository design](docs/repository-design.md) | Where content belongs and what each area owns |
| [Architecture Decision Records](docs/decisions/README.md) | Durable decisions and their status |

## License

Licensed under the [Apache License 2.0](LICENSE).
