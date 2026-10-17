# Changelog

What changed for someone consuming this toolkit, in the format [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) describes, with versions following [Semantic Versioning](https://semver.org/).

This file records consumer-facing change. It does not restate platform targets or evidence, which belong to [Compatibility](docs/compatibility.md), or the rules governing releases, which belong to the [release policy](docs/release-policy.md).

## Unreleased

### Changed

- **The repository is now `proxmox-iac-toolkit`,** renamed from `homelab-iac-toolkit`. Commits and tags are unchanged, so the full SHA you record still names the same source, and no module, role, input, output or behaviour changed. The worked example's checkout convention is now `vendor/proxmox-iac-toolkit/`. Update any Git remote or module `source` that names the old repository, keeping the same commit, and either keep your checkout path or change every reference to it together. No state change is involved. [Using the toolkit](docs/consuming-the-toolkit.md#moving-from-homelab-iac-toolkit) has the commands.
- **The `proxmox-linux-vm` module rejects more malformed inputs when you plan.** `ipv4_address_cidr`, `ipv4_gateway` and IPv4 `dns_servers` must be dotted decimal without leading zeros, `ipv4_address_cidr` needs a prefix length from 8 to 32, and an IPv4-mapped IPv6 address is no longer read as IPv4. Each `ssh_public_keys` entry must be one key on one line, with at most two base64 padding characters. A configuration that used one of these values planned before and now stops at plan with the module's message; correct the value as the message says. `vm_id` and `network_vlan_id` left at `null` no longer fail validation on older OpenTofu releases. [Compatibility](docs/compatibility.md#opentofu-cli-compatibility-and-evidence) records the versions checked.

## 0.1.0-alpha.1 - 2026-09-08

### Added

- **An OpenTofu module, `proxmox-linux-vm`,** that creates one Proxmox VE Linux VM as a full clone of a cloud-init template you supply. It takes your node, template, datastore, sizing, bridge, static IPv4 addressing, and a bootstrap account, and it configures no provider and declares no backend, so both stay yours. It publishes a non-sensitive `connection` output — host, user and port — for you to compose inventory from by hand.
- **An Ansible role, `qemu_guest_agent`,** that installs the QEMU guest agent in a Linux guest and brings its service up. It takes ordinary inventory, reads no OpenTofu state, and manages no Proxmox resource, so it works against any host you can already reach.
- **A coordinated way to consume both together:** one checkout of this repository at one immutable full commit SHA, recorded in your own source control, with the module resolved through a local path into it and Ansible's `roles_path` reaching the same checkout. One commit therefore determines both component implementations.
- **A worked example**, `examples/separate-consumer-repository/`, showing that arrangement as a separate repository would hold it, including the manual mapping from the module's `connection` output into ordinary inventory.
- **Consumer documentation**, [Using the toolkit](docs/consuming-the-toolkit.md), covering the workflow, what you own, and what to check when a checkout, a role path, or an input does not resolve.

### Notes for consumers

- **The guest-agent channel is attached when the VM is created**, which is what lets the role start the service on its first run. Turning it off produces a VM where the agent cannot run, and reversing that costs a stop and start.
- **Destroy stops the VM by default** rather than asking the guest to shut down. That is predictable, and it can interrupt a running workload and lose unwritten data. The [module README](tofu/modules/proxmox-linux-vm/README.md) sets out both settings.
- **No validation in this repository has run against a Proxmox VE or a guest.** Every check is credential-free and structural. [Compatibility](docs/compatibility.md) records what that evidence does and does not demonstrate.

### Migration

None. `0.1.0-alpha.1` is the initial release of this toolkit, so there is no earlier release to migrate from.
