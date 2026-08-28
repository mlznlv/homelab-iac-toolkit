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

This list describes the project direction, not currently available functionality.

## Repository model

This public repository will contain reusable toolkit components, documentation, examples, and validation.

A separate private deployment repository will contain concrete environment configuration. The public toolkit must remain usable without access to private deployment data.

Everything in this repository must be safe to publish and must not contain real secrets or private deployment data.

## Status

The project is currently in its bootstrap, pre-release stage, with its initial roadmap and design documentation being developed.

## Roadmap and documentation

The project roadmap, architecture documentation, and Architecture Decision Records will be added as the design is developed and approved.

## License

Licensed under the [Apache License 2.0](LICENSE).
