# `qemu_guest_agent`

Install the `qemu-guest-agent` package and start its service in a suitable VM. The role takes
ordinary inventory and has no OpenTofu or Proxmox API dependency.

## Requirements

The guest needs Python supported by the declared Ansible toolchain, APT, systemd, the
`qemu-guest-agent` package/service, an attached guest-agent channel and SSH access able to
perform privileged operations non-interactively. [Compatibility](../../../docs/compatibility.md)
owns target distributions and evidence.

The [VM module](../../../tofu/modules/proxmox-linux-vm/README.md#guest-agent-and-destroy)
describes channel creation, later enablement and the interval before the agent runs. Consumers
own inventory, private keys, authentication, privilege configuration and ordering. The role does
not set `become`; both tasks require root privileges.

## Quick start

Put the pinned checkout's `ansible/roles` on `roles_path` in your `ansible.cfg`:

```ini
[defaults]
roles_path = ./vendor/proxmox-iac-toolkit/ansible/roles
```

Then use it in a play against your inventory:

```yaml
- name: Install and start the QEMU guest agent
  hosts: fictional_guests
  become: true
  roles:
    - role: qemu_guest_agent
```

The [consumer example](../../../examples/separate-consumer-repository/README.md) shows the
complete handoff and invocation.

## Interface and lifecycle

There are no role variables, handlers or templates. The package is present and the service
running; boot-enabling is honored only where packaging supports it. On device-activated static
units, `systemctl is-enabled` reports `static`, Ansible treats that as already enabled and udev
starts the service when its device appears. There is no guest-side enablement configuration to
add for such a unit.

## Limitations and validation

The role configures no agent settings, users, SSH or other guest state. It creates no inventory,
waits for no VM, and reads no state/output or infrastructure credentials. It does not apply to
LXC containers.

[`tests/`](tests) supplies a syntax fixture and static contract check, alongside Ansible lint.
The check reads all executable task/handler paths and rejects opaque includes, action forms or
dependencies it cannot inspect. Required package/service behavior, module use, consumer-owned
privilege and lack of OpenTofu coupling are checked under
[Contributing](../../../CONTRIBUTING.md#validate-your-change). These are structural checks;
[Compatibility](../../../docs/compatibility.md#current-evidence-level) records the absence of
runtime convergence/idempotency evidence.
