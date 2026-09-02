# `qemu_guest_agent`

An Ansible role that installs the QEMU guest agent in a Linux guest and brings its service up.

That is the whole of it: two tasks, no variables, no handlers, no templates. Proxmox can then report the guest's addresses, and shut it down gracefully, because something inside the guest is answering.

## What you own

The role takes ordinary inventory and nothing else. It never reads OpenTofu state or outputs, generates no inventory, and manages no Proxmox resource — you can use it against any host you can already reach, whether or not this toolkit created it.

It also deliberately does not set `become`. Both of its tasks need root, and how you get there — `become`, a privileged connection user, your own sudo policy — is your decision to make in your play or inventory, not one this role should take from you.

You own the inventory, the credentials and private keys, the privilege configuration, and when the role runs.

## Requirements

The guest must have:

- a Python interpreter Ansible can use, at a version the declared `ansible-core` supports;
- APT package management;
- systemd;
- a `qemu-guest-agent` package and service under that name;
- **the guest-agent channel attached to the VM** — the service is bound to that device, so without it the service cannot start no matter what is installed;
- SSH access with an identity that can perform privileged operations non-interactively.

The channel is the one prerequisite you cannot fix from inside the guest. The [`proxmox-linux-vm`](../../../tofu/modules/proxmox-linux-vm/README.md) module attaches it at creation, and any other VM created with its QEMU guest agent option enabled has it too. On a VM created without it, attaching it later means stopping and starting the VM.

[Compatibility](../../../docs/compatibility.md) is the authority on that contract. It names Debian Stable and Kali Rolling as **expected-compatible** targets: they meet the capabilities above, and nothing in this repository has run this role against either of them, or against any other guest. They are not validated reference platforms, and no result here should be read as though they were.

## What the role promises

The service **is running**, and **enabled where the packaging supports enabling it**.

The second half is not a hedge. On the expected-compatible targets named above, the unit is device-activated: bound to the guest-agent channel, started from a udev rule when that device appears, and shipping an empty `[Install]` section. `systemctl is-enabled` reports `static`, which Ansible reads as already enabled, so the role's enable step is a no-op there — correctly, because there is nothing to enable. Where packaging does ship an `[Install]` section, the same task enables the unit for boot.

Anything stronger would be a claim about packaging this role does not control, on distributions it has never run against.

## Usage

Put this repository's `ansible/roles` on your roles path, then use the role in a play:

```yaml
- name: Install the QEMU guest agent and bring its service up
  hosts: fictional_guests
  become: true
  roles:
    - role: qemu_guest_agent
```

The roles path can come from your `ansible.cfg`:

```ini
[defaults]
roles_path = ./vendor/homelab-iac-toolkit/ansible/roles
```

or from the environment, which is how this repository's own checks do it:

```sh
ANSIBLE_ROLES_PATH=ansible/roles ansible-playbook --inventory inventory.yml play.yml
```

Composing this with the [`proxmox-linux-vm`](../../../tofu/modules/proxmox-linux-vm/README.md) module is your job and stays that way: apply the module, build inventory however you build inventory, then run the role. That is the whole sequence — the module attaches the channel at creation, so there is no second apply to remember and nothing to switch on afterwards.

## Limitations

- One package, one service. It configures nothing inside the agent and owns no other guest state.
- It creates no users and does not touch SSH configuration; the OpenTofu module's cloud-init bootstrap is where an initial account comes from, and after that the account is yours.
- It makes no Proxmox API call and needs no Proxmox credential.
- It has no opinion about ordering: nothing here waits for a VM to exist, and nothing wires it to an infrastructure run.

## How this role is checked

Three credential-free checks, all runnable with `task validate:ansible` and documented individually in [Local validation](../../../docs/validation.md):

| Check | What it establishes |
| --- | --- |
| `ansible-playbook --syntax-check` on [`tests/role.yml`](tests/role.yml) | A minimal play using the role parses, with a fictional inventory that resolves nowhere. |
| `ansible-lint` on the role and that fixture | The role and fixture meet ansible-lint's rules at its `production` profile. |
| [`tests/check-role-contract.py`](tests/check-role-contract.py) | The role still declares what it claims: the package present through Ansible's package management, the service started through its service management, no shell command standing in for a module, no `become` taken from the consumer, and no OpenTofu reference in anything it executes. It reads every task and handler file and walks tasks nested in `block`, `rescue` and `always`. Anything that would run content it has not read fails it: an include resolving outside the role, a module named through `action` or `local_action` instead of directly, another role pulled in, or a role dependency declared in `meta`. That is what lets "everything it executes" be a claim the check can actually make. |

None of them contacts a guest, needs a credential, or runs the role. They are evidence about what the role declares — not that a package installed, not that a service came up, not that the role converges or is idempotent on any distribution, and not that Proxmox subsequently saw a guest agent.
