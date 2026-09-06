# Using the toolkit from your own repository

This toolkit is meant to be consumed from a repository that is not this one. Your repository holds the configuration that describes your environment; this one holds the reusable parts and never learns anything about it.

There is a [worked example](../examples/separate-consumer-repository) of the whole arrangement. This page explains the shape it has and why, and what to look at when something does not resolve. Read the example for the concrete files and the step-by-step sequence; it is the thing this page describes, and its paths and commands are real.

## One checkout, one commit

The toolkit has two halves that are used together: the [`proxmox-linux-vm`](../tofu/modules/proxmox-linux-vm) OpenTofu module and the [`qemu_guest_agent`](../ansible/roles/qemu_guest_agent) Ansible role. They have no runtime dependency on one another and neither knows the other exists.

You record one immutable full commit SHA in your own source control, establish one checkout at that revision, and resolve both halves out of it — OpenTofu through a local module `source`, Ansible through an ordinary `roles_path`. That single shared checkout is the whole contract.

Pinning each half separately would work right up until the two pins drifted onto different revisions, at which point nothing would tell you. [ADR 0007](decisions/0007-single-revision-consumer-contract.md) records the decision, and [Architecture](architecture.md#initial-separate-repository-consumer-contract) states it in context.

**A full SHA, not a branch or a tag.** Both of those can move, and a moving pin is not a pin.

## What you own

Everything environment-shaped, which is most of it:

| Yours | Notes |
| --- | --- |
| The checkout: how you obtain it, where you put it, when you update it | A submodule pinned to the SHA, a vendored copy whose origin and revision you record, or any other fetch you control |
| OpenTofu inputs | Node, template, datastore, bridge, addresses, sizing, identifiers |
| Provider configuration, endpoint, credentials | The module declares no `provider` block |
| Backend and state custody | The module declares no backend |
| Ansible inventory and authentication | Including the private half of every key you authorize |
| Execution order | Nothing here runs anything for you |

The toolkit owns the module and role interfaces and what they do internally. It does not acquire, update, synchronize, or choose your checkout, and neither OpenTofu, Ansible, nor Task does it on the toolkit's behalf.

`vendor/homelab-iac-toolkit/` is a convention rather than a toolkit interface: nothing in the module or the role knows that path. It is not, however, free to change on its own. OpenTofu requires a module `source` to be a literal, so the example writes the path into `tofu/main.tf` and again into `ansible.cfg`. Putting your checkout somewhere else means editing both — and editing them **to the same place**, since two paths that disagree are exactly the silent drift this contract exists to prevent.

## The workflow

The [example's Getting Started](../examples/separate-consumer-repository#getting-started) has the sequence with real paths and commands: record the SHA, establish the checkout, review the configuration, plan, **read the plan**, apply explicitly, map the connection values into inventory by hand, then run the play.

Two of those steps are deliberate rather than unfinished. **A person reviews the plan** — nothing here is built for an unattended apply, and copying the example does not make one safe. **The inventory is written by hand** — you copy the module's three `connection` values into `ansible_host`, `ansible_user` and `ansible_port` yourself. Nothing reads OpenTofu state, generates inventory, or wires the output through automatically, and the role does not know OpenTofu exists.

## Credentials, state, and secrets

**Provider endpoints and credentials** are supplied at run time through the provider's own mechanisms, which [the provider documents](https://search.opentofu.org/provider/bpg/proxmox/latest). They are not toolkit interfaces and do not belong in source control.

**The example declares no backend.** As committed it has never been applied and holds no state — but **applying it creates a real VM and real state**, and with no backend declared that state is written to a local file with nothing protecting it. Choose a backend and a state-custody policy before you apply anything, including this example: OpenTofu state records what was created and can hold sensitive values. The omission keeps the example free of a choice that is yours; it is not a recommendation to use local state.

**The initial workflow commits no encrypted document**, so it needs no secret loader, credential broker, or decryption step, and the toolkit adds none. SOPS and age remain the interface for a workflow that does require committed encrypted secrets, deferred rather than rejected, as [ADR 0007](decisions/0007-single-revision-consumer-contract.md) records. Runtime credentials stay outside Git.

Encrypted material and the recipients it was encrypted to are consumer-owned and never appear in this public toolkit. **The decryption identity is different in kind: it is a private key, so keep it out of Git.** An age identity or SSH private key that would open your secrets should live on the machines that need it and be distributed the way you already distribute private keys — committing it, to any repository, defeats the encryption it unlocks.

## What the checks here prove

This repository validates the components and the example on every change, without credentials and without reaching any Proxmox host or guest. It does use the public network: the checks download the provider the configuration declares, and resolve the links in this documentation. Those checks establish that the configuration parses, the module call type-checks against the module's real interface, both halves resolve from one represented checkout, the committed inventory is the `connection` output mapped unchanged, and the play resolves the role.

They establish nothing about a running system, and no check here has ever run against a Proxmox VE or a guest. [Compatibility](compatibility.md#current-evidence-level) enumerates what this evidence does not demonstrate.

A full commit SHA selects exact pre-release source. It creates no semantic-versioning, upgrade, migration, stability, or release-support guarantee; those remain M5 decisions.

## Troubleshooting

These are the failures the accepted workflow actually produces, with the output that identifies each. They are all contract-level and none of them requires a live environment to diagnose.

Problems on a running system — a VM that does not come up, cloud-init that does not apply, SSH that refuses, a play that does not converge, an agent Proxmox does not report — are outside what any check here exercises, and nothing on this page diagnoses them.

### The module source does not resolve

```text
Error: Unreadable module directory
The directory  could not be read for module "guest" at main.tf:20.
```

`tofu init` could not find the module at the local path in your root configuration. Either the checkout is not established at the path the `source` points to, or the `source` is relative to the wrong place — OpenTofu resolves it against the directory of the file declaring it, not the directory you ran from.

### The role is not found

```text
[ERROR]: The role 'qemu_guest_agent' was not found in: <consumer>/ansible/roles:<consumer>/vendor/homelab-iac-toolkit/ansible/roles:<consumer>/ansible
```

**Read the search path in the error, because it distinguishes the two causes.** If your checkout path appears in the list, as above, then `ansible.cfg` was read and its `roles_path` is right, but nothing is at that path — the checkout is not established.

If instead the list holds Ansible's defaults and your checkout path is missing:

```text
[WARNING]: No inventory was parsed, only implicit localhost is available
[ERROR]: The role 'qemu_guest_agent' was not found in: <consumer>/ansible/roles:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:<consumer>/ansible
```

then `ansible.cfg` was never loaded at all. Ansible looks for it in the working directory, so run the play from the directory holding it, or name it in `ANSIBLE_CONFIG`. The accompanying inventory warning is the same cause: the inventory setting lives in that unread file.

Relative paths inside `ansible.cfg` resolve against the directory holding the file, not the working directory, so they keep pointing at the same places once the file is found.

### A required input is missing

```text
Error: Missing required argument
  on main.tf line 20, in module "guest":
The argument "node_name" is required, but no definition was found.
```

The module defaults none of its **required** inputs — every value describing your environment is named explicitly, because no default could be right for it. Four optional inputs do have defaults: `guest_agent_enabled`, `stop_on_destroy` and `ssh_port` choose behaviour, and `vm_id` defaults to `null`, which leaves Proxmox to assign the next free identifier rather than choosing one for you. [Its README](../tofu/modules/proxmox-linux-vm/README.md) lists both sets.

### An input is rejected

```text
var.ipv4_address_cidr is "192.0.2.10"
The ipv4_address_cidr must be an IPv4 address with a prefix length, such as
192.0.2.10/24.
```

The module validates its inputs and says what it expected. The message names the rule that rejected the value.

### The inventory has drifted from the configuration

If you keep the example's `tofu/tests/`, an address changed in one file and not the other fails there:

```text
tests/inventory-mapping.tftest.hcl... fail
  run "the_committed_inventory_is_the_connection_output_mapped_by_hand"... fail
```

Because the mapping is manual, nothing else notices. That test is worth keeping once the values are yours.

### The play matches no hosts

```text
[WARNING]: Could not match supplied host pattern, ignoring: fictional_guests
```

The play's `hosts:` names a group your inventory does not define. This is a warning rather than an error, and a syntax check still passes, so it is easy to miss: the play simply runs against nothing.

### The revision is not what you think

Nothing reports this, which is the reason the contract exists. If the two halves behave as though they came from different versions of the toolkit, check that the module `source` and the `roles_path` reach the *same* directory, and that the checkout there is at the SHA your source control records.

### The guest agent cannot start

The module attaches the guest-agent channel when it creates the VM, which is what lets the role start the service on its first run. If the channel is turned off, the agent cannot run, and adding the channel afterwards requires stopping and starting the VM — Proxmox does not hot-plug it. [ADR 0006](decisions/0006-guest-agent-channel-at-creation.md) records the ordering and [Compatibility](compatibility.md#guest-capability-contract) records the guest requirements.

Whether an agent actually starts on your guest is not something any check here establishes.
