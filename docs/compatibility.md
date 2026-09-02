# Compatibility

This document is the public compatibility contract for approved reusable toolkit components. It records current platform targets and the level of evidence supporting them. It is not a release guarantee or a duplicate tool-version manifest.

Executable tool versions remain authoritative in [Supported tool versions](toolchain.md). Exact provider constraints belong in the OpenTofu module's source-controlled provider requirements when the module exists.

## Proxmox VE target

The first reusable OpenTofu module supports Proxmox VE 9.x through the `bpg/proxmox` provider.

The supported PVE major is explicit and does not float when a new major is released. Adopting another major requires deliberate compatibility review, corresponding validation, and an update to this declaration and the module's executable constraints where applicable. A new ADR is required only when that review changes the durable compatibility policy or another architectural decision.

The toolkit owns the provider requirement and reusable module interface. Consumers continue to own concrete provider configuration, credentials, endpoints, backend configuration, and state.

## Guest capability contract

The `qemu_guest_agent` role requires a managed guest with:

- a Python version supported by the repository's declared Ansible toolchain;
- APT package management;
- systemd service management;
- the `qemu-guest-agent` package and service available under that name;
- the guest-agent channel present in the VM, because the service is bound to that device on the targets below and cannot start without it; and
- SSH access through an identity able to perform the role's privileged operations non-interactively.

Debian Stable and Kali Rolling are expected-compatible targets for this capability contract. They are not runtime-validated reference platforms under the current evidence model. Other Debian-family distributions that meet the same capabilities may also work, but the toolkit makes no distribution-wide guarantee.

On those targets the guest-agent unit is device-activated: it is bound to the guest-agent channel, started from a udev rule when that device appears, and carries no installation configuration, so `systemctl is-enabled` reports `static`. The role's obligation there is that the package is installed and the service is running; enabling it for boot is not something a guest can configure, and the toolkit does not claim it.

The consumer-supplied source template must support the cloud-init bootstrap inputs used by the OpenTofu module: static IPv4 addressing, gateway, DNS servers, username, and SSH public keys. The template need not contain `qemu-guest-agent`: the module attaches the channel at creation and waits for no agent, so the package arrives afterwards with the Ansible role.

## Current evidence level

The first slice requires public, credential-free static and contract validation for:

- module inputs, input validation, full-clone configuration, static addressing, the guest-agent channel attached at creation with provider IP waiting disabled, the default and overridden destroy policy, and the required `connection` output;
- Ansible syntax, lint, and the static package and service contract;
- connection-value composition without an OpenTofu-state dependency in the role; and
- repository validation and publication safety.

This evidence does not demonstrate:

- live compatibility with a PVE 9.x installation or a particular `bpg/proxmox` release;
- successful plan, apply, clone, start, reconciliation, or destroy behavior, including graceful shutdown or reliable forced stop;
- successful cloud-init execution, SSH connectivity, or privilege escalation;
- Ansible convergence or idempotency on Debian Stable, Kali Rolling, or another real guest;
- that a guest agent starts once the channel is present, or that Proxmox subsequently reports one; or
- that adding or removing the channel behaves as described on a running VM.

Static or mocked evidence must not be described as live infrastructure or guest compatibility evidence. A distribution becomes a validated reference platform only after public validation exercises it to the level claimed and this contract records that evidence.
