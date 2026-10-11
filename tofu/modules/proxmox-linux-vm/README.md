# `proxmox-linux-vm`

An OpenTofu module that creates one Proxmox VE Linux VM as a full clone of a cloud-init template you already have, gives it static IPv4 addressing, optionally with static IPv6 beside it, and a bootstrap account, and publishes where that account can be reached.

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
- if you tag the network device, the VLAN and everything that carries it: the bridge's configuration, upstream switching and routing, and addressing that belongs on that VLAN;
- if you declare IPv6, the prefix it comes from and everything that makes it work: address uniqueness, routing, router advertisements, upstream IPv6 service, and a gateway that belongs on that network;
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
| `ipv4_address_cidr` | `string` | Static IPv4 address with a prefix length, such as `192.0.2.10/24`. Required even when IPv6 is declared. |
| `ipv4_gateway` | `string` | IPv4 default gateway, without a prefix length. |
| `dns_servers` | `list(string)` | IPv4 or IPv6 DNS servers, in order of preference. At least one. |
| `username` | `string` | Bootstrap account cloud-init creates. |
| `ssh_public_keys` | `list(string)` | OpenSSH **public** keys authorized for that account. At least one. |

Optional:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `vm_id` | `number` | `null` | VM identifier. Proxmox assigns the next free one when this is null. |
| `guest_agent_enabled` | `bool` | `true` | Whether to attach the guest-agent channel. Off produces a VM where the agent cannot run. |
| `stop_on_destroy` | `bool` | `true` | Whether destroy stops the VM instead of asking the guest to shut down. |
| `ssh_port` | `number` | `22` | Port published in the `connection` output. Metadata only. |
| `network_vlan_id` | `number` | `null` | Access VLAN tag for the single network device, `1` to `4094`. Null leaves it untagged. See [VLAN tagging](#vlan-tagging). |
| `ipv6_address_cidr` | `string` | `null` | Static IPv6 address with a prefix length from `8` to `128`, such as `2001:db8::10/64`, added beside the IPv4 addressing. Null declares no IPv6. See [Static IPv6](#static-ipv6). |
| `ipv6_gateway` | `string` | `null` | IPv6 default gateway, global or link-local, without a prefix length. Needs `ipv6_address_cidr`. |

Values that can be judged without contacting Proxmox are checked when you plan, not when Proxmox rejects them: an address without a prefix length, an IPv6 address in an IPv4 input or an IPv4 one in an IPv6 input, a gateway carrying a prefix, an IPv6 gateway without an IPv6 address, an IPv6 prefix length outside `8` to `128`, Proxmox's non-address IPv6 forms `auto`, `dhcp`, and `manual`, a DNS server that is not an IPv4 or IPv6 address, an empty key list, a value that is not an OpenSSH public key line, an identifier outside Proxmox's range, a VLAN tag that is not a whole number from `1` to `4094`, and so on.

## Outputs

| Name | Description |
| --- | --- |
| `connection` | `{ host, user, port }` — the declared IPv4 address without its prefix, the bootstrap username, and `ssh_port`. Never the IPv6 address. |
| `vm_id` | Identifier of the created VM, supplied or assigned. |
| `vm_name` | Name of the created VM. |

All three are non-sensitive; the module never publishes a private key or a password, and never accepts one.

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

`network_vlan_id` puts one access VLAN tag on the VM's single network device. Leave it `null`, the default, and the device stays untagged and attached; set it to a whole number from `1` to `4094` to tag it.

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

## Static IPv6

`ipv6_address_cidr` adds a static IPv6 address to the VM's existing cloud-init IP configuration, beside the static IPv4 address rather than in place of it. Leave it `null`, the default, and the module declares no IPv6 and plans exactly as before. `ipv6_gateway` optionally adds an IPv6 default gateway, global or link-local; it needs the address.

```hcl
module "fictional_vm" {
  # ...the other inputs shown in Usage...

  ipv4_address_cidr = "192.0.2.10/24"
  ipv4_gateway      = "192.0.2.1"

  ipv6_address_cidr = "2001:db8::10/64"
  ipv6_gateway      = "fe80::1"

  dns_servers = ["2001:db8::53", "192.0.2.53"]
}
```

The IPv6 addresses come from the [RFC 3849](https://www.rfc-editor.org/info/rfc3849/) documentation prefix and name nothing real. DNS servers may be IPv4, IPv6, or both, with or without IPv6 addressing, and at least one is still required.

Only static IPv6 is supported. Proxmox also accepts `auto` for stateless autoconfiguration, `dhcp` for DHCPv6, and `manual` in the same field, but cloud-init's renderers do not give the first two one meaning, so the module rejects all three when you plan. If your network relies on either for guests, configure IPv6 inside the guest instead. IPv6-only addressing is not supported either: the IPv4 inputs stay required.

The declared IPv6 address never becomes `connection.host`, which stays the declared IPv4 address. Adding IPv6 to an existing VM therefore leaves your inventory as it was.

The module puts the address and gateway into the cloud-init network data and nothing more. For IPv6 to work in the guest, you provide:

- a template whose cloud-init renders a static IPv6 subnet and its gateway;
- the prefix the address comes from, and an address no other host uses;
- routing and upstream IPv6 service on the bridge's network, and router advertisements if you rely on them;
- a gateway that is reachable on that network. When you leave the gateway out, the module makes no claim about where the guest's IPv6 default route comes from. Nothing checks that the address, gateway, and network agree.

**Adding, changing, or removing IPv6 on an existing VM reboots it.** The VM is updated in place rather than replaced, but any change to its cloud-init configuration makes the provider rebuild the cloud-init drive and reboot a running VM. The next boot is a new cloud-init instance: it re-applies the network configuration, and unless your template turns that off it regenerates the guest's SSH host keys, so expect a host-key warning on your next connection. The same is true of a change to the DNS servers.

**Removing the declared address does not remove IPv6 from the guest.** It removes the address and gateway from the cloud-init network data. Addresses the guest configures for itself, such as link-local ones or those it derives from router advertisements, are outside the declaration.

Read the plan before you apply. An IPv6-only change shows the VM as `update in-place`, with only `initialization` changing. If a plan shows the VM being replaced for an IPv6 change, do not apply it: that is not the behaviour this module relies on.

That in-place behaviour is evidenced for the provider build this repository locks, `bpg/proxmox` v0.111.1, at provider level: its schema and source, and credential-free plans made with that build for adding IPv6 with and without a gateway, changing the address, prefix length, and gateway, adding and removing the gateway, and removing IPv6, each followed by a plan from the state the provider's read would record afterwards, which showed no further change. It has not been observed against a real Proxmox VE, and nothing here shows that a guest configures the address, that the gateway or any route works, that the guest is reachable over IPv6, or that it has no other IPv6 addresses. [Compatibility](../../../docs/compatibility.md#static-ipv6-addressing) records that boundary, and that your own root module's lock decides which provider build you run.

## Limitations

This module is one VM, cloned once, addressed statically. It does not do:

- template creation or upkeep;
- disk resizing, extra disks, or any disk management — the clone inherits the template's layout;
- linked clones, or cloning from a template on another node;
- DHCP, IPv6 stateless autoconfiguration or DHCPv6, IPv6-only addressing, VLAN trunks, or more than one network interface;
- VLAN creation, bridge configuration or discovery, or network configuration inside the guest;
- guest packages, services, users, authorized keys, or SSH configuration after cloud-init;
- LXC containers, HA, pools, or firewall rules.

## How this module is checked

Formatting, `tofu validate`, and a set of contract tests under [`tests/`](tests) that run against a **mocked** provider: no Proxmox endpoint, no credentials, nothing created. Run them with `task validate:tofu`, or directly as [Local validation](../../../docs/validation.md) describes.

They prove what the module asks the provider for — one full clone of the declared template, the declared static addressing and bootstrap account, the guest-agent channel attached by default and absent when it is turned off, waiting for an agent-reported address disabled in both cases, `stop_on_destroy` on both settings reaching the resource, the `connection` output's derivation, the network device left untagged by default and tagged with `1` and `4094` without gaining a second device or changing the addressing or `connection` output, IPv6 absent by default and, when declared, its address and global or link-local gateway reaching the existing IP configuration beside the static IPv4 one without changing the `connection` output, IPv6 DNS servers accepted beside IPv4 ones — and that bad input fails at plan time.

They prove nothing about a real Proxmox VE. No clone, boot, cloud-init run, SSH connection, shutdown, stop, destroy, VLAN change, IPv6 change, or guest agent has been exercised. Nor can a mocked provider show that a tag or IPv6 change is made in place; [VLAN tagging](#vlan-tagging) and [Static IPv6](#static-ipv6) say where that evidence comes from. [Compatibility](../../../docs/compatibility.md) records what this evidence does and does not cover.

`.terraform.lock.hcl` is committed so those checks resolve the same provider build every time, verified against recorded hashes, on Linux and macOS. It governs this repository's own validation. Your root module has its own lock file; this one does not constrain it.
