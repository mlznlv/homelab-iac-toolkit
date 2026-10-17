# Proxmox IaC Toolkit

Reusable OpenTofu modules and Ansible roles for Proxmox VE homelabs, composed from a separate
consumer repository. Public source contains reusable code and fictional examples; your
repository holds deployment configuration.

The toolkit is at an early pre-release stage. Read the [compatibility
evidence](docs/compatibility.md) before choosing a component.

## Quick start

1. Choose a toolkit revision and record its full commit SHA in your repository.
2. Establish one checkout and follow [Using the toolkit](docs/using.md).
3. Adapt the [consumer example](examples/separate-consumer-repository/README.md),
   review a plan, then apply explicitly and configure the guest.

To work on the toolkit itself, follow [Contributing](CONTRIBUTING.md).

## Components

| Component | Purpose |
| --- | --- |
| [Linux VM](tofu/modules/proxmox-linux-vm/README.md) | Full clone of a cloud-init template; static/DHCP IPv4, optional static IPv6 and additional attachments |
| [Linux container](tofu/modules/proxmox-linux-container/README.md) | Unprivileged Debian LXC, one static IPv4 interface |
| [QEMU guest agent](ansible/roles/qemu_guest_agent/README.md) | Install and start the agent inside a suitable VM |
| [Separate consumer repository](examples/separate-consumer-repository/README.md) | Compose the VM and role from one pinned checkout |

## Guides

| Guide | Purpose |
| --- | --- |
| [Using](docs/using.md) | Consumption, upgrades and troubleshooting |
| [Contributing](CONTRIBUTING.md) | Setup, validation and documentation ownership |
| [Security](SECURITY.md) | Publication safety and reporting |
| [Architecture](docs/architecture.md) | Boundaries, dependencies and ownership |
| [Compatibility](docs/compatibility.md) | Targets and evidence levels |
| [Roadmap](docs/roadmap.md) | Near-term direction; execution tracking lives in issues |
| [Decisions](docs/decisions/README.md) | Durable rationale and ADR convention |
| [Release policy](docs/release-policy.md) | Release gates, immutability and corrections |
| [Changelog](CHANGELOG.md) | Consumer-visible changes |

Licensed under [Apache 2.0](LICENSE).
