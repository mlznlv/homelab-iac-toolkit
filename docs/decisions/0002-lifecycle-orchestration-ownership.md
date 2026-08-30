# ADR 0002: Lifecycle and orchestration ownership

## Status

Accepted

## Context

The toolchain includes OpenTofu, Ansible, Task, SOPS, age, scripts, and GitHub Actions. Without explicit boundaries, multiple tools could manage the same concern and produce conflicting state or non-deterministic behavior.

## Decision

OpenTofu owns Proxmox infrastructure lifecycle, including supported resources, disks, resource allocation, network attachments, and infrastructure dependencies.

Ansible owns continuing guest configuration, including packages, users, operating-system configuration, application configuration, and services.

OpenTofu may provide minimal creation-time bootstrap required to make a guest manageable. It must not become the continuing guest-configuration system. Ansible must not create or destroy Proxmox resources.

Task owns workflow orchestration only. It invokes documented commands and may aggregate checks, but it owns no infrastructure, guest configuration, secrets, or hidden state.

SOPS and age define the secrets-encryption boundary. The public toolkit may define reusable interfaces and sanitized examples, but real secret material and decryption identities remain consumer concerns and never enter normal public CI.

Git is the durable source of truth for reusable source, configuration, documentation, and accepted decisions. Generated runtime data is not a competing source of truth.

Scripts and CI may invoke lifecycle owners but must not create a competing implementation of their behavior.

## Consequences

- Each lifecycle concern has one authoritative owner.
- Cross-tool interaction uses explicit inputs, outputs, and documented handoffs.
- Task and scripts remain inspectable workflow conveniences.
- Minimal guest bootstrap must be distinguished from ongoing guest convergence.
- Overlapping ownership requires a new architecture decision rather than an implementation shortcut.
