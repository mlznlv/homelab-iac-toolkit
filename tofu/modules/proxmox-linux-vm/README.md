# `proxmox-linux-vm`

An OpenTofu module that creates one Proxmox VE Linux VM as a full clone of a cloud-init template you already have, gives it static IPv4 addressing and a bootstrap account, and publishes where that account can be reached.

It is deliberately small. It owns the VM's lifecycle in Proxmox and nothing else: it configures no provider, keeps no state, manages no disks, and stops caring about the guest's users, keys, and SSH configuration the moment cloud-init has run. Installing the guest agent afterwards belongs to Ansible, and composing the two is yours.

## Requirements

| Requires | Version |
| --- | --- |
| OpenTofu | 1.6.0 or later. This repository's own checks run it at the version declared in [`.tool-versions`](../../../.tool-versions). |
| Provider | [`bpg/proxmox`](https://search.opentofu.org/provider/bpg/proxmox/latest), `~> 0.111.0` |
| Proxmox VE | 9.x, as declared in [Compatibility](../../../docs/compatibility.md) |

The provider constraint is deliberately narrow. `bpg/proxmox` is pre-1.0, so a minor release may change behaviour; adopting one is a compatibility decision rather than an automatic upgrade.

You supply, and continue to own:

- provider configuration, the endpoint, and credentials — this module declares no `provider` block;
- backend configuration and state;
- a Proxmox VM template on the target node that has `cloud-init` and reads the addressing, user, and SSH-key data this module sets;
- the datastore, node, bridge, addresses, sizing, and identifiers below;
- the private half of the SSH keys you authorize.

## Usage

```hcl
module "fictional_vm" {
  source = "git::https://github.com/mlznlv/homelab-iac-toolkit.git//tofu/modules/proxmox-linux-vm?ref=<commit>"

  name         = "fictional-vm"
  node_name    = "fictional-node"
  template_id  = 9000
  datastore_id = "fictional-datastore"

  cpu_cores      = 2
  memory_mib     = 2048
  network_bridge = "vmbr0"

  ipv4_address_cidr = "192.0.2.10/24"
  ipv4_gateway      = "192.0.2.1"
  dns_servers       = ["192.0.2.53"]

  username        = "fictional"
  ssh_public_keys = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
}
```

Every value above is fictional or reserved for documentation: the addresses come from [RFC 5737](https://www.rfc-editor.org/info/rfc5737/) and name nothing real. Pin `ref` to a commit or tag; this project has not published a release yet.

## Inputs

Required:

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | VM name. Proxmox requires a valid DNS label. |
| `node_name` | `string` | Proxmox node to create the VM on. The template must be on this node. |
| `template_id` | `number` | Identifier of the cloud-init template to clone. |
| `datastore_id` | `string` | Datastore for the cloned disks and the cloud-init drive. |
| `cpu_cores` | `number` | CPU cores. |
| `memory_mib` | `number` | Dedicated memory, in MiB. |
| `network_bridge` | `string` | Bridge for the VM's single network device, such as `vmbr0`. |
| `ipv4_address_cidr` | `string` | Static IPv4 address with a prefix length, such as `192.0.2.10/24`. |
| `ipv4_gateway` | `string` | IPv4 default gateway, without a prefix length. |
| `dns_servers` | `list(string)` | IPv4 DNS servers, in order of preference. At least one. |
| `username` | `string` | Bootstrap account cloud-init creates. |
| `ssh_public_keys` | `list(string)` | OpenSSH **public** keys authorized for that account. At least one. |

Optional:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `vm_id` | `number` | `null` | VM identifier. Proxmox assigns the next free one when this is null. |
| `guest_agent_enabled` | `bool` | `true` | Whether to attach the guest-agent channel. Off produces a VM where the agent cannot run. |
| `stop_on_destroy` | `bool` | `true` | Whether destroy stops the VM instead of asking the guest to shut down. |
| `ssh_port` | `number` | `22` | Port published in the `connection` output. Metadata only. |

Values that can be judged without contacting Proxmox are checked when you plan, not when Proxmox rejects them: an address without a prefix length, an IPv6 address, a gateway carrying a prefix, a DNS server that is not an IPv4 address, an empty key list, a value that is not an OpenSSH public key line, an identifier outside Proxmox's range, and so on.

## Outputs

| Name | Description |
| --- | --- |
| `connection` | `{ host, user, port }` — the declared IPv4 address without its prefix, the bootstrap username, and `ssh_port`. |
| `vm_id` | Identifier of the created VM, supplied or assigned. |
| `vm_name` | Name of the created VM. |

All three are non-sensitive; the module never publishes a private key or a password, and never accepts one.

`connection` exists so you can build your own inventory out of values you already declared. Nothing in this toolkit reads it: the Ansible side of the accepted first slice takes ordinary inventory and knows nothing about OpenTofu.

## Destroying the VM

`stop_on_destroy` is the one input that can lose data, and neither value is free.

**`true` (default)** — destroy stops the VM, the way pulling power does. It does not depend on ACPI or on a guest agent, so it completes predictably, and it can interrupt a running workload and lose whatever the guest had not written to disk.

**`false`** — destroy asks the guest to shut down first, which is gentler when it works. When shutdown does not happen, destroy blocks or times out.

Who performs that shutdown depends on when you destroy. Before the agent is installed, Proxmox probes it, gets nothing, and falls back to ACPI. Once the agent is running, Proxmox asks the agent — the graceful shutdown this input is really after. The default stays `true` precisely because a destroy should not depend on which side of that line it lands on.

Set it to `false` when your guests shut down reliably and you would rather wait than lose unwritten data. Either way, destroy is destructive and OpenTofu shows you the plan first.

## The guest agent

The VM is created with the guest-agent channel attached, and the module never waits for an agent to answer.

Both halves matter, and they are separate things. Proxmox only adds the `org.qemu.guest_agent.0` device when the agent setting is enabled, and a Debian guest's `qemu-guest-agent.service` is bound to that device — so a VM created without the channel is one where the service can never start, whatever you install inside it. Waiting is the other half: a provider that waits for an agent-reported address would block every apply and refresh until it timed out. This module disables that wait unconditionally, which is why attaching the channel early costs nothing at apply time. Addressing is always the static configuration you declared.

So the composition is one apply, then guest configuration: create the VM, build your inventory, install the agent with the [Ansible guest-agent capability](../../../docs/architecture.md#ansible-guest-agent-capability). There is no second apply and no power cycle, which [ADR 0006](../../../docs/decisions/0006-guest-agent-channel-at-creation.md) records in full.

**Between creating the VM and installing the agent**, Proxmox believes the guest has an agent that is not answering yet. Each affected operation degrades differently, and none of them hangs:

| Operation | Behaviour in that window |
| --- | --- |
| Shutdown, reboot | Proxmox probes the agent for three seconds, warns, and falls back to ACPI. |
| Backup | The guest filesystem freeze is skipped and logged. The backup is crash-consistent rather than filesystem-consistent — the one real cost, and a reason to close the window before relying on backups. |
| Agent queries, agent-reported addresses | Reported unavailable. |

Setting `guest_agent_enabled = false` is supported and means something specific: a VM in which the guest agent cannot run at all. Attaching the channel later requires stopping and starting the VM, because Proxmox does not hot-plug that change.

## Limitations

This module is one VM, cloned once, addressed statically. It does not do:

- template creation or upkeep;
- disk resizing, extra disks, or any disk management — the clone inherits the template's layout;
- linked clones, or cloning from a template on another node;
- DHCP, IPv6, VLAN tags, or more than one network interface;
- guest packages, services, users, authorized keys, or SSH configuration after cloud-init;
- LXC containers, HA, pools, or firewall rules.

## How this module is checked

Formatting, `tofu validate`, and a set of contract tests under [`tests/`](tests) that run against a **mocked** provider: no Proxmox endpoint, no credentials, nothing created. Run them with `task validate:tofu`, or directly as [Local validation](../../../docs/validation.md) describes.

They prove what the module asks the provider for — one full clone of the declared template, the declared static addressing and bootstrap account, the guest-agent channel attached by default and absent when it is turned off, waiting for an agent-reported address disabled in both cases, `stop_on_destroy` on both settings reaching the resource, the `connection` output's derivation — and that bad input fails at plan time.

They prove nothing about a real Proxmox VE. No clone, boot, cloud-init run, SSH connection, shutdown, stop, destroy, or guest agent has been exercised. [Compatibility](../../../docs/compatibility.md) records what this evidence does and does not cover.

`.terraform.lock.hcl` is committed so those checks resolve the same provider build every time, verified against recorded hashes, on Linux and macOS. It governs this repository's own validation. Your root module has its own lock file; this one does not constrain it.
