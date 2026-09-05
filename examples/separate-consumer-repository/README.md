# A separate consumer repository

This directory is shaped like the repository you would keep for your own homelab: it is not part of the toolkit's source, and nothing in the toolkit reads it. It exists to show one thing — how a repository that is not this one uses both halves of the toolkit together, from a single checkout pinned at a single commit.

The two halves are the [`proxmox-linux-vm`](../../tofu/modules/proxmox-linux-vm) OpenTofu module and the [`qemu_guest_agent`](../../ansible/roles/qemu_guest_agent) Ansible role. They have no runtime dependency on each other, and neither knows the other exists. What ties them together here is that both are resolved out of the same directory, at the same revision, which [ADR 0007](../../docs/decisions/0007-single-revision-consumer-contract.md) records as the reason this example is shaped the way it is.

**This is not deployment-ready, and copying it does not make it so.** Every value in it is fictional, it declares no backend, it holds no credentials, and no part of it has ever run against a Proxmox host. Read [What is actually proven](#what-is-actually-proven) before relying on any of it.

## The layout

```text
toolkit-revision.yml            the full commit SHA this repository pins
tofu/
  versions.tf                   the provider, configured by you, and no backend
  main.tf                       the module, from a local path in the checkout
  outputs.tf                    the connection values you read after an apply
ansible/
  ansible.cfg                   roles_path, reaching the same checkout
  inventory.yml                 the connection values, mapped in by hand
  guest-agent.yml               the play that runs the role
vendor/homelab-iac-toolkit/     the checkout — you create this; see step 1
```

`tests/` is this toolkit's check of the example, not part of it. Do not copy it.

The one thing both `tofu/main.tf` and `ansible/ansible.cfg` have in common is `vendor/homelab-iac-toolkit/`. That is the contract: one directory, one commit, both components. Point them at two different checkouts and they can drift onto two different revisions of the toolkit without anything complaining.

## What you supply

The toolkit supplies neither, and this example contains neither:

- **the checkout.** How you obtain it and where you put it are yours, along with any credentials that takes. A Git submodule pinned to the full SHA, a vendored copy whose origin and revision you record, or any other fetch you control all satisfy the contract. `vendor/homelab-iac-toolkit/` is this example's convention, not a toolkit interface. Nothing in the toolkit acquires, updates, verifies, or synchronizes it.
- **everything environment-specific.** The Proxmox endpoint and credentials, the backend and state custody, the node, template, datastore, bridge, addresses, sizing, the SSH keys you authorize and their private halves, how Ansible authenticates, and the order you run things in.

## Getting started

Nothing below is automated, and the ordering is deliberate: a human reviews a plan before anything is created, and a human writes the inventory afterwards.

**1. Establish the checkout at the pinned revision.** Read `toolkit-revision.yml`, then obtain that commit into `vendor/homelab-iac-toolkit/` by whatever mechanism you have chosen. The revision recorded there is synthetic and names no commit; replace it with the full SHA you actually checked out. A full SHA is the point — a branch or a tag can move, and then the two components are no longer pinned together.

**2. Review the configuration.** `tofu/main.tf` and `ansible/inventory.yml` are entirely fictional. Replace every value in them with yours before going further.

**3. Configure the provider.** `tofu/versions.tf` declares an empty `provider "proxmox"` block. Supply the endpoint and credentials at run time through the provider's own environment variables, which [the provider documents](https://search.opentofu.org/provider/bpg/proxmox/latest). They are not toolkit interfaces, and they do not belong in this repository.

**4. Plan, and read the plan.**

```sh
cd tofu
tofu init
tofu plan
```

**5. Apply, explicitly, after that review.**

```sh
tofu apply
```

**6. Map the connection values into inventory by hand.**

```sh
tofu output connection
```

That prints three values — `host`, `user`, and `port`. Copy them into `ansible/inventory.yml` as `ansible_host`, `ansible_user`, and `ansible_port`. Doing it by hand is the design, not an omission: nothing here reads OpenTofu state, generates inventory, or wires the output through automatically, so composing the two components stays a step you take deliberately.

**7. Run the play.**

```sh
cd ../ansible
ansible-playbook guest-agent.yml
```

Run it from that directory. Ansible resolves the relative paths inside `ansible.cfg` against the directory holding the file, but it only finds the file at all when it is the working directory.

## Two things this example does not decide for you

**There is no backend.** `tofu/versions.tf` declares none, because this example creates nothing and has no state worth protecting. That is not a recommendation to use local state for a real deployment. OpenTofu state records what was created and can hold sensitive values, so choose a backend and a state-custody policy before your first real apply.

**There are no secrets, and no mechanism for them.** The initial workflow needs no encrypted document in source control, so the toolkit adds no secret loader, credential broker, or decryption step. Runtime credentials stay outside Git and reach the provider and Ansible through their own mechanisms. Real secret material, recipients, and decryption identities are yours and belong in your own private repository.

## What is actually proven

This repository checks the example on every change. Those checks are credential-free and read only what is declared. They establish that:

- the example parses, and its module call type-checks against the module's real interface;
- the OpenTofu module source and the Ansible `roles_path` resolve into the same represented checkout;
- `ansible/inventory.yml` is the module's `connection` output mapped into `ansible_host`, `ansible_user`, and `ansible_port` with no value changed;
- the play resolves `qemu_guest_agent` from that same checkout; and
- the example carries no acquisition, orchestration, state-reading, inventory-generation, or secret-handling mechanism, and no real address, host, or credential.

They establish nothing else. **No part of this example has been run against a Proxmox host or a guest.** Steps 4 through 7 above are the accepted workflow, not a tested path: this repository has never executed a `tofu plan`, `tofu apply`, or `ansible-playbook` run outside the credential-free checks described here. Nothing here is evidence about provisioning, cloud-init, SSH connectivity, Ansible convergence or idempotency, `qemu-guest-agent` runtime behaviour, or shutdown, reboot, backup, and destroy behaviour. [Compatibility](../../docs/compatibility.md) records what the project does and does not claim.

Pinning a full commit SHA selects exact pre-release source. It is not a release, and it carries no semantic-versioning, upgrade, migration, stability, or support guarantee.
