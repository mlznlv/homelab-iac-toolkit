# `proxmox-linux-vm`

An OpenTofu module that creates one Proxmox VE Linux VM as a full clone of a cloud-init template you already have, gives it static IPv4 addressing, optional additional network attachments and a bootstrap account, and publishes where that account can be reached.

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
- if you tag a network device, the VLAN and everything that carries it: the bridge's configuration, upstream switching and routing, and addressing that belongs on that VLAN;
- if you add network attachments, their bridges and networks, allocating their addresses, and any routing between them;
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
| `network_bridge` | `string` | Bridge for the VM's primary network device, `net0`, such as `vmbr0`. |
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
| `network_vlan_id` | `number` | `null` | Access VLAN tag for the primary network device, `1` to `4094`. Null leaves it untagged. See [VLAN tagging](#vlan-tagging). |
| `additional_network_attachments` | `list(object)` | `[]` | Up to seven more network attachments, `net1` onwards, in the order given. See [Additional network attachments](#additional-network-attachments). |

Values that can be judged without contacting Proxmox are checked when you plan, not when Proxmox rejects them: an address without a prefix length, an IPv6 address, a gateway carrying a prefix, a DNS server that is not an IPv4 address, an empty key list, a value that is not an OpenSSH public key line, an identifier outside Proxmox's range, a VLAN tag that is not a whole number from `1` to `4094`, more than eight network attachments, the same IPv4 address on two attachments, a MAC address that is malformed or multicast, and so on.

## Outputs

| Name | Description |
| --- | --- |
| `connection` | `{ host, user, port }` — the declared IPv4 address without its prefix, the bootstrap username, and `ssh_port`. |
| `mac_addresses` | MAC address of every network attachment, in slot order: `net0` first. Declared ones as given, the rest as Proxmox assigned them. |
| `vm_id` | Identifier of the created VM, supplied or assigned. |
| `vm_name` | Name of the created VM. |

All four are non-sensitive; the module never publishes a private key or a password, and never accepts one.

`connection` exists so you can build your own inventory out of values you already declared. Nothing in this toolkit consumes it at run time: the Ansible side of the accepted first slice takes ordinary inventory and knows nothing about OpenTofu. A contract fixture, [`tests/composition-inventory.yml`](tests/composition-inventory.yml), shows what that composition looks like and is asserted against this output — which is a demonstration that the mapping holds, not a dependency between the two components.

## Destroying the VM

`stop_on_destroy` is the one input that can lose data, and neither value is free.

**`true` (default)** — destroy stops the VM, the way pulling power does. It does not depend on ACPI or on a guest agent, so it completes predictably, and it can interrupt a running workload and lose whatever the guest had not written to disk.

**`false`** — destroy asks the guest to shut down first, which is gentler when it works and blocks or times out when it does not. Who performs that shutdown depends on when you destroy: before the agent is installed Proxmox falls back to ACPI, and once it is running Proxmox asks the agent. The default stays `true` precisely because a destroy should not depend on which side of that line it lands on.

Set it to `false` when your guests shut down reliably and you would rather wait than lose unwritten data. Either way, destroy is destructive and OpenTofu shows you the plan first.

## The guest agent

The VM is created with the guest-agent channel attached, and the module never waits for an agent to answer. Those are separate things and both matter: Proxmox adds the `org.qemu.guest_agent.0` device only when the agent setting is enabled, and a Debian guest's `qemu-guest-agent.service` is bound to that device, so a VM created without the channel is one where the service can never start. Meanwhile a provider that waited for an agent-reported address would block every apply and refresh until it timed out, so this module disables that wait unconditionally and addressing is always the static configuration you declared.

The composition is therefore one apply, then guest configuration: create the VM, build your inventory, install the agent with the [Ansible guest-agent capability](../../../docs/architecture.md#ansible-guest-agent-capability). No second apply, no power cycle. [ADR 0006](../../../docs/decisions/0006-guest-agent-channel-at-creation.md) records it in full.

**Between creating the VM and installing the agent**, Proxmox believes the guest has an agent that is not answering yet. Each affected operation degrades differently, and none of them hangs:

| Operation | Behaviour in that window |
| --- | --- |
| Shutdown, reboot | Proxmox probes the agent for three seconds, warns, and falls back to ACPI. |
| Backup | The guest filesystem freeze is skipped and logged. The backup is crash-consistent rather than filesystem-consistent — the one real cost, and a reason to close the window before relying on backups. |
| Agent queries, agent-reported addresses | Reported unavailable. |

Setting `guest_agent_enabled = false` is supported and means something specific: a VM in which the guest agent cannot run at all. Attaching the channel later requires stopping and starting the VM, because Proxmox does not hot-plug that change.

## VLAN tagging

`network_vlan_id` puts one access VLAN tag on the VM's primary network device. An [additional attachment](#additional-network-attachments) takes its own `vlan_id` with the same rules. Leave it `null`, the default, and the device stays untagged and attached; set it to a whole number from `1` to `4094` to tag it.

```hcl
module "fictional_vm" {
  # ...the other inputs shown in Usage...

  network_bridge  = "vmbr0"
  network_vlan_id = 42

  ipv4_address_cidr = "192.0.2.10/24"
  ipv4_gateway      = "192.0.2.1"
  dns_servers       = ["192.0.2.53"]
}
```

The tag is as fictional as the addresses. `0` is rejected: the provider uses it internally to mean untagged, and `null` is this module's only way to say that.

The module sets the tag on the Proxmox side of the attachment and nothing more. For a tagged VM to reach anything, you provide:

- a bridge on the node configured to carry the VLAN you choose;
- upstream switching and routing that deliver that VLAN;
- a static address, gateway, and DNS servers that belong on that VLAN. The module does not check that they agree with the tag.

It does not create VLANs, configure or discover bridges, expose trunks, or configure a VLAN interface inside the guest.

**Changing the tag of an existing VM interrupts its network link.** Adding, changing, or removing the tag updates the VM in place rather than replacing it, but Proxmox applies the change to a running VM by detaching and re-attaching its virtual link, so the guest sees the link go down even when everything around it is configured correctly. Whether connectivity comes back depends on the bridge, VLAN, switching, routing, and addressing above, not on this module.

Read the plan before you apply. A tag-only change shows the VM as `update in-place`. If a plan shows the VM being replaced for a tag-only change, do not apply it: that is not the behaviour this module relies on. Check which provider build your root module's lock selects, because only the build named below has been evaluated.

That in-place behaviour is evidenced for the provider build this repository locks, `bpg/proxmox` v0.111.1, at provider level: its schema and source, and credential-free plans made with that build for untagged-to-tagged, tagged-to-different-tag, and tagged-to-untagged changes. It has not been observed against a real Proxmox VE, and nothing here shows that a tag is applied successfully, that a bridge or upstream network carries it, or that the guest stays reachable. [Compatibility](../../../docs/compatibility.md#optional-vlan-capability) records that boundary, and that your own root module's lock decides which provider build you run.

## Additional network attachments

`additional_network_attachments` adds network attachments after the primary one. The primary attachment is the one the inputs above describe: it is always `net0` and cloud-init IP configuration `0`, and it keeps every input, default, and output it had. Leave the list empty, the default, and the VM plans exactly as before.

```hcl
module "fictional_vm" {
  # ...the other inputs shown in Usage...

  additional_network_attachments = [
    {
      bridge            = "vmbr1"
      vlan_id           = 42
      ipv4_address_cidr = "198.51.100.10/24"
    },
    {
      bridge      = "vmbr2"
      mac_address = "00:00:5E:00:53:01"
    },
  ]
}
```

The addresses are from [RFC 5737](https://www.rfc-editor.org/info/rfc5737/) and the MAC address from the range [RFC 7042](https://www.rfc-editor.org/info/rfc7042/) reserves for documentation. Each entry needs a `bridge` and may set:

| Attribute | Meaning |
| --- | --- |
| `vlan_id` | Access VLAN tag, `1` to `4094`, with the same rules as [`network_vlan_id`](#vlan-tagging). Null leaves the device untagged. |
| `ipv4_address_cidr` | Static IPv4 address with a prefix length. Null gives the attachment no cloud-init IP configuration of its own. |
| `mac_address` | Unicast MAC address written as six colon-separated hexadecimal octets, used as given. Null lets Proxmox assign one. |

There is no gateway. Only the primary attachment has one, so the guest never receives a second default route, and routing between attachments is guest configuration. OpenTofu ignores a key the type does not declare, so a `gateway` written on an additional attachment does nothing.

As with VLAN tags, the module sets the Proxmox side of each attachment and nothing more. It does not check that an address belongs on its bridge or VLAN, and it does not configure interfaces inside the guest.

### Position is identity

An attachment is its position in the list. The first entry is `net1` with cloud-init IP configuration `1`, the next is `net2`, and so on. Seven entries fit, for eight attachments in total, because the provider carries at most eight cloud-init IP configurations.

The guest recognizes an interface by its MAC address: the network data Proxmox generates for cloud-init matches each addressed interface to the MAC address of the device in its slot, and names it `eth` followed by the slot number. `mac_addresses` reports every attachment's MAC address in slot order, `net0` first. In the plan that adds an attachment without `mac_address`, its entry reads `null` rather than a value known after apply; the address Proxmox assigns appears once that apply has run, so read it from a later plan or apply.

### Changing attachments on an existing VM

No attachment change replaces the VM. With the provider build this repository locks, each of these plans the VM as `update in-place`:

| Change | What the guest sees |
| --- | --- |
| Add an attachment after the last one | A new device. |
| Remove the last attachment | Its device disappears. |
| Change an attachment's `bridge` or `vlan_id` | The same device, with the link interruption described for [VLAN changes](#vlan-tagging). |
| Change a declared `mac_address`, or declare one where Proxmox assigned it | A different device: Proxmox unplugs the old one and plugs in one with the new address. |
| Stop declaring a `mac_address` | Nothing. The device keeps the address it has, and the plan shows no change. |
| Remove or reorder any attachment but the last | Every later slot is re-mapped, as described below. |

**Removing or reordering any attachment but the last re-maps every later slot.** When an entry leaves the middle of the list, each later slot takes the next entry's bridge, VLAN, address, and declared MAC address, and the last slot is removed. A MAC address that Proxmox assigned stays with its slot rather than with its entry: remove the first of two attachments that declare no MAC address, and `net1` keeps its MAC address while taking the second attachment's bridge, VLAN, and address. A declared MAC address moves with its entry, so the device in that slot is replaced. Either way, every later interface changes identity or network. The module cannot warn you, because input validation cannot see what the VM had before. If later interfaces must stay stable, remove attachments from the end.

**Changing any attachment's address reboots the VM.** This covers adding, changing, or removing an address, adding or removing an addressed attachment, a re-map that moves an address, and the primary attachment's own `ipv4_address_cidr`. Each changes the cloud-init data, and with the locked provider's defaults that rebuilds the cloud-init drive and reboots a running VM. The changed data also gives the VM a new cloud-init instance identifier, so on that boot cloud-init treats the guest as a new instance. It re-applies network configuration and, unless your template's cloud-init configuration says otherwise, deletes and regenerates the guest's SSH host keys. Expect the reboot, and expect host-key verification to change. Adding or removing an attachment without an address at the end of the list leaves the cloud-init data unchanged.

### Removing an address leaves it in Proxmox

The provider sends Proxmox only the IP configurations that declare something, and never deletes one. When you remove an addressed attachment, or remove the address from an attachment, the retired `ipconfig` entry stays in the VM's configuration in Proxmox. Two things follow.

- **The retired address can reach another device.** Proxmox generates cloud-init network data for every slot that still has an IP configuration, and matches it to whichever device is in that slot now. An attachment later placed in the slot, or moved into it by a re-map, can boot with the retired address. An attachment without an address is guaranteed no cloud-init configuration only in a slot that has never had one.
- **The plan does not settle.** OpenTofu reads the retired entry back, finds that your configuration does not declare it, and plans an in-place update to remove it again on every plan. Applying that update removes nothing, and it rebuilds the cloud-init drive and reboots a running VM each time. The plan settles only after the retired entry has been removed from the VM's configuration in Proxmox, which this module does not do.

Read the plan before you apply. If it shows the VM being replaced for an attachment change, do not apply it: that is not the behaviour this module relies on. If it shows a cloud-init IP configuration being removed when you changed no address, you are looking at a retired entry.

That behaviour is evidenced for the provider build this repository locks, `bpg/proxmox` v0.111.1, at provider level: its source, and credential-free plans made with that build for each change in the table, the re-map with assigned and declared MAC addresses, and the retired entry being read back. It has not been observed against a real Proxmox VE. Nothing here shows that a device is plugged or unplugged successfully, that a guest names, configures, or brings up an interface, that cloud-init re-applies configuration or regenerates host keys on your template, or that anything is reachable or routed through any attachment. [Compatibility](../../../docs/compatibility.md#multiple-network-attachments) records that boundary, and your root module's own lock decides which provider build you run.

## Limitations

This module is one VM, cloned once, addressed statically. It does not do:

- template creation or upkeep;
- disk resizing, extra disks, or any disk management — the clone inherits the template's layout;
- linked clones, or cloning from a template on another node;
- DHCP, IPv6, VLAN trunks, or more than eight network attachments;
- a gateway or routes on any attachment but the primary, NIC models, firewall, MTU, rate, queue, or link-state settings;
- VLAN creation, bridge configuration or discovery, or network configuration inside the guest;
- guest packages, services, users, authorized keys, or SSH configuration after cloud-init;
- LXC containers, HA, pools, or firewall rules.

## How this module is checked

Formatting, `tofu validate`, and a set of contract tests under [`tests/`](tests) that run against a **mocked** provider: no Proxmox endpoint, no credentials, nothing created. Run them with `task validate:tofu`, or directly as [Local validation](../../../docs/validation.md) describes.

They prove what the module asks the provider for — one full clone of the declared template, the declared static addressing and bootstrap account, the guest-agent channel attached by default and absent when it is turned off, waiting for an agent-reported address disabled in both cases, `stop_on_destroy` on both settings reaching the resource, the `connection` output's derivation, the network device left untagged by default and tagged with `1` and `4094` without gaining a second device or changing the addressing or `connection` output, no additional attachment by default, additional attachments in the declared order from `net1` with their own bridge, tag, address, and MAC address, no gateway on any of them, an empty IP configuration for an addressless attachment before an addressed one and none after the last addressed one, eight attachments accepted, `mac_addresses` in slot order, and the primary attachment and `connection` output unchanged by them — and that bad input fails at plan time.

They prove nothing about a real Proxmox VE. No clone, boot, cloud-init run, SSH connection, shutdown, stop, destroy, VLAN change, attachment change, or guest agent has been exercised. Nor can a mocked provider show that a tag or attachment change is made in place; [VLAN tagging](#vlan-tagging) and [Additional network attachments](#additional-network-attachments) say where that evidence comes from. [Compatibility](../../../docs/compatibility.md) records what this evidence does and does not cover.

`.terraform.lock.hcl` is committed so those checks resolve the same provider build every time, verified against recorded hashes, on Linux and macOS. It governs this repository's own validation. Your root module has its own lock file; this one does not constrain it.
