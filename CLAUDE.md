# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This repository is in its bootstrap, pre-release stage: it currently contains only project documentation, licensing, and GitHub governance templates (issue templates, PR template). There is no source code, build system, or test suite yet, so there are no build/lint/test commands to run. As toolkit code (OpenTofu, Ansible, Task, etc.) is added, this file should be updated with the actual commands.

## What this repository is

A reusable, open-source infrastructure-as-code toolkit for Proxmox VE homelabs (see README.md). It is meant to provide public building blocks — infrastructure and configuration modules, examples, and validation — that a separate, private deployment repository composes with environment-specific configuration.

The intended technology stack:

- [OpenTofu](https://opentofu.org/) for infrastructure provisioning
- [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview) as the virtualization platform
- [Ansible](https://www.ansible.com/) for configuration management
- [Task](https://taskfile.dev/) as the task runner
- [SOPS](https://github.com/getsops/sops) + [age](https://age-encryption.org/) for secrets encryption
- GitHub Actions for CI

## Architectural constraint: public/private split

The core design principle of this project is separating reusable toolkit code (this repo) from concrete environment configuration (a separate private repo). This has one hard consequence for any change made here: **everything committed to this repository must be safe to publish** — no real secrets, no private deployment data, no generated state — and the toolkit must remain usable without access to the private deployment repository.

## Contribution workflow

The GitHub issue/PR templates encode a specific process — follow it when creating or reviewing issues/PRs in this repo:

1. **Specification** (`Spec` issue template): an implementation-ready unit of work, owned by Product Ownership, and must reference an approved roadmap item. It defines outcome, scope, out-of-scope items, acceptance criteria, dependencies, and architecture alignment (or flags that architecture review is still required). Architecture decisions are not made inside a spec issue.
2. **Implementation task** (`Task` issue template): tracks implementation of exactly one approved specification. It records only implementation/validation status, not a restatement of the spec, and requires the linked spec to be approved with no unresolved architecture decisions before work starts.
3. **Pull request** (`pull_request_template.md`): must stay within the approved specification it closes, contain no unrelated changes, and not introduce secrets/private data/generated state. Architecture decisions are expected to already be documented and approved outside the PR itself.

Roadmap, architecture documentation, and ADRs are expected to live in this repository as the project matures (per README.md), but do not exist yet.
