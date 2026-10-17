# `proxmox-linux-vm`

An OpenTofu module that creates one Proxmox VE Linux VM as a full clone of a cloud-init template you already have, gives it static or DHCP IPv4 addressing with optional static IPv6 beside it, optional additional network attachments and a bootstrap account, and publishes where that account can be reached.

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
- if you choose DHCP, the DHCP service with its scopes, reservations, and leases, and a connection host that keeps reaching the guest;
- if you declare IPv6, the prefix it comes from and everything that makes it work: address uniqueness, routing, router advertisements, upstream IPv6 service, and a gateway that belongs on that network;
- the private half of the SSH keys you authorize.

## Usage

```hcl
module "fictional_vm" {
  source = "git::https://github.com/mlznlv/proxmox-iac-toolkit.git//tofu/modules/proxmox-linux-vm?ref=<commit>"

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
| `ipv4_address_cidr` | `string` | Static IPv4 address in dotted decimal with a prefix length from 8 to 32, such as `192.0.2.10/24`. Required in static mode, the default; must be null with [DHCP](#dhcp-addressing). |
| `ipv4_gateway` | `string` | IPv4 default gateway in dotted decimal, without a prefix length. Required in static mode; must be null with DHCP. |
| `dns_servers` | `list(string)` | IPv4 or IPv6 DNS servers, in order of preference. At least one. |
| `username` | `string` | Bootstrap account cloud-init creates. |
| `ssh_public_keys` | `list(string)` | OpenSSH **public** keys authorized for that account. At least one, each a single key on one line; a trailing newline is allowed. |

Optional:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `vm_id` | `number` | `null` | VM identifier. Proxmox assigns the next free one when this is null. |
| `guest_agent_enabled` | `bool` | `true` | Whether to attach the guest-agent channel. Off produces a VM where the agent cannot run. |
| `stop_on_destroy` | `bool` | `true` | Whether destroy stops the VM instead of asking the guest to shut down. |
| `ssh_port` | `number` | `22` | Port published in the `connection` output. Metadata only. |
| `network_vlan_id` | `number` | `null` | Access VLAN tag for the primary network device, `1` to `4094`. Null leaves it untagged. See [VLAN tagging](#vlan-tagging). |
| `ipv4_mode` | `string` | `"static"` | IPv4 addressing mode of the primary attachment: `"static"` or `"dhcp"`. See [DHCP addressing](#dhcp-addressing). |
| `connection_host` | `string` | `null` | Host published in the `connection` output: a hostname or an IPv4 or IPv6 address. Required with DHCP. Metadata only. |
| `network_mac_address` | `string` | `null` | MAC address for the primary network device, `net0`. Null lets Proxmox assign one. |
| `additional_network_attachments` | `list(object)` | `[]` | Up to seven more network attachments, `net1` onwards, in the order given. On an existing VM they can be added and changed, not removed or reordered. See [Additional network attachments](#additional-network-attachments). |
| `ipv6_address_cidr` | `string` | `null` | Static IPv6 address with a prefix length from `8` to `128`, such as `2001:db8::10/64`, added to the primary attachment beside its IPv4 addressing. Null declares no IPv6. See [Static IPv6](#static-ipv6). |
| `ipv6_gateway` | `string` | `null` | IPv6 default gateway, global or link-local, without a prefix length. Needs `ipv6_address_cidr`. |

Values that can be judged without contacting Proxmox are checked when you plan, not when Proxmox rejects them: an address without a prefix length, an IPv6 address in an IPv4 input or an IPv4 one in an IPv6 input, an IPv4 address, gateway, or DNS server with an octet written with a leading zero, an IPv4 prefix length outside `8` to `32`, a gateway carrying a prefix, an IPv6 gateway without an IPv6 address, an IPv6 prefix length outside `8` to `128`, Proxmox's non-address IPv6 forms `auto`, `dhcp`, and `manual`, a DNS server that is not an IPv4 or IPv6 address, an empty key list, an entry that is not one OpenSSH public key on one line, an identifier outside Proxmox's range, a VLAN tag that is not a whole number from `1` to `4094`, more than eight network attachments, a null in place of the attachment list, an additional address that is not dotted-decimal IPv4, the same IPv4 address on two attachments, a MAC address that is malformed or multicast, the same MAC address declared on two attachments, an addressing mode other than `static` or `dhcp`, a static configuration missing its address or gateway, a DHCP configuration that declares either or supplies no connection host, a connection host that is not a hostname or a plainly written IP address, and so on.

## Outputs

| Name | Description |
| --- | --- |
| `connection` | `{ host, user, port }` — `connection_host` when you supply one, otherwise the declared IPv4 address without its prefix, never the declared IPv6 address; the bootstrap username; and `ssh_port`. |
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

The VM is created with the guest-agent channel attached, and the module never waits for an agent to answer. Those are separate things and both matter: Proxmox adds the `org.qemu.guest_agent.0` device only when the agent setting is enabled, and a Debian guest's `qemu-guest-agent.service` is bound to that device, so a VM created without the channel is one where the service can never start. Meanwhile a provider that waited for an agent-reported address would block every apply and refresh until it timed out, so this module disables that wait unconditionally and addressing is always what you declared: a static address, or DHCP with a connection host you supply.

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
- addressing that belongs on that VLAN, a static address and gateway or a DHCP service, and DNS servers that serve it. The module does not check that they agree with the tag.

It does not create VLANs, configure or discover bridges, expose trunks, or configure a VLAN interface inside the guest.

**Changing the tag of an existing VM interrupts its network link.** Adding, changing, or removing the tag updates the VM in place rather than replacing it, but Proxmox applies the change to a running VM by detaching and re-attaching its virtual link, so the guest sees the link go down even when everything around it is configured correctly. Whether connectivity comes back depends on the bridge, VLAN, switching, routing, and addressing above, not on this module.

Read the plan before you apply. A tag-only change shows the VM as `update in-place`. If a plan shows the VM being replaced for a tag-only change, do not apply it: that is not the behaviour this module relies on. Check which provider build your root module's lock selects, because only the build named below has been evaluated.

That in-place behaviour is evidenced for the provider build this repository locks, `bpg/proxmox` v0.111.1, at provider level: its schema and source, and credential-free plans made with that build for untagged-to-tagged, tagged-to-different-tag, and tagged-to-untagged changes. It has not been observed against a real Proxmox VE, and nothing here shows that a tag is applied successfully, that a bridge or upstream network carries it, or that the guest stays reachable. [Compatibility](../../../docs/compatibility.md#optional-vlan-capability) records that boundary, and that your own root module's lock decides which provider build you run.

## DHCP addressing

`ipv4_mode` chooses how the primary attachment gets its IPv4 address. `"static"`, the default, is the addressing the rest of this README describes, and a configuration that does not set `ipv4_mode` plans exactly as before. `"dhcp"` asks cloud-init to request a DHCPv4 lease on the primary interface instead.

```hcl
module "fictional_vm" {
  # ...the other inputs shown in Usage, without ipv4_address_cidr and ipv4_gateway...

  ipv4_mode       = "dhcp"
  connection_host = "fictional-vm.example.invalid"
  dns_servers     = ["192.0.2.53"]

  network_mac_address = "00:00:5E:00:53:01"
}
```

The name is from [RFC 2606](https://www.rfc-editor.org/info/rfc2606/) and the MAC address from the range [RFC 7042](https://www.rfc-editor.org/info/rfc7042/) reserves for documentation.

DHCP changes three inputs:

- **`ipv4_address_cidr` and `ipv4_gateway` must be null.** The DHCP service supplies the address, and Proxmox expects no gateway alongside DHCP. Static mode still requires both.
- **`connection_host` is required.** The module cannot know the address your DHCP service will grant, and it never finds out. See [The connection host](#the-connection-host).
- **`dns_servers` stays required.** Without it Proxmox would give the guest the node's own resolvers, which this module will not choose for you.

DHCP is for the primary attachment only. An [additional attachment](#additional-network-attachments) stays static or addressless whatever the primary does.

The module declares that the primary attachment uses DHCP, and its MAC address if you give one. Everything else that makes DHCP work is yours:

- the DHCP service, its scopes, reservations, and leases, on the network the primary attachment reaches;
- names that resolve to the guest, if you publish one as the connection host, and keeping them accurate;
- a template whose cloud-init renders a DHCPv4 configuration into a running DHCP client.

Apply finishes without any evidence that a lease was granted or that the guest can be reached.

### The connection host

The `connection` output keeps its `host`, `user`, and `port` shape in both modes. `connection_host` decides `host`:

| Mode | `connection_host` | `connection.host` |
| --- | --- | --- |
| Static | null | The declared address without its prefix, as before |
| Static | set | `connection_host` |
| DHCP | set | `connection_host` |
| DHCP | null | Rejected when you plan |

It takes a hostname, such as `fictional-vm.example.invalid`, or an IPv4 or IPv6 address, written without a scheme, brackets, or port. An IPv4 address must be plain dotted decimal: `192.0.2.010` and `0x7f000001` are refused, because the resolver SSH and Ansible use would read them as octal and hexadecimal and reach `192.0.2.8` and `127.0.0.1`. It is declared metadata, the same as `ssh_port`. The module never resolves it, never checks that it reaches the guest, and never fills it in from a lease, a guest agent, a provider read, OpenTofu state, or generated inventory. In static mode it lets you publish a name instead of the address.

### The primary MAC address

`network_mac_address` sets the MAC address of the primary network device, `net0`. It is optional in both modes, takes the same form as an additional attachment's `mac_address`, and is used as given. Declared MAC addresses must differ across the primary and every additional attachment, whatever letter case each is written in. As for additional attachments, that rule covers only what you declare in one configuration.

Declare it when a DHCP reservation must match from the first boot, and create the reservation for that address before you apply. Leave it null and Proxmox assigns one when the VM is created, so nothing can be reserved for the first boot: `mac_addresses` reports the assigned address, `net0` first, once that apply has run.

Changing it, or declaring one where Proxmox assigned it, updates the VM in place, but on a running VM Proxmox unplugs the device and plugs in one with the new address. The guest sees a different interface, and a reservation keyed to the old address stops matching. Stop declaring it and nothing changes: the device keeps the address it has.

### Switching an existing VM between static and DHCP

Changing `ipv4_mode` on an existing VM updates it in place; it does not replace it. With the provider build this repository locks, the plan changes only the primary cloud-init IP configuration, and once that update is applied the next plan proposes nothing.

It is still disruptive. As for any [address change](#changing-attachments-on-an-existing-vm), it rebuilds the cloud-init drive and reboots a running VM, and the next boot is a new cloud-init instance. Cloud-init re-applies network configuration and, unless your template's configuration says otherwise, deletes and regenerates the guest's SSH host keys. The guest's address can change, so update anything that depends on it, including the connection host, a DNS record, and known host keys.

Changing only `connection_host` changes no infrastructure: the plan shows a different `connection` output and no change to the VM.

Read the plan before you apply. A mode switch shows the VM as `update in-place`, with only `ipconfig0` changing. If a plan shows the VM being replaced, do not apply it: that is not the behaviour this module relies on. Check which provider build your root module's lock selects, because only the build named below has been evaluated.

### Where the DHCP behaviour is evidenced

All of the above is for the provider build this repository locks, `bpg/proxmox` v0.111.1, at provider level, and the evidence comes in the same three kinds as for [additional attachments](#where-this-is-evidenced).

- **Plans.** Credential-free plans made with that build, with refresh disabled, against synthetic prior states: an existing static VM picking up this module unchanged, creation in DHCP mode and with a declared primary MAC address, static to DHCP and back with and without an additional attachment, a connection-host-only change, and declaring, changing, and no longer declaring the primary MAC address.
- **Modelled read-back.** Each change was then planned again against a state modelled on the provider's read path, and proposed nothing. No apply and no refresh was run.
- **Source.** That the provider sends `ipconfig0` as `ip=dhcp` with no gateway and reads an absent gateway back as empty, that Proxmox stores the IP configuration as sent and commits it on a running VM, and that a changed MAC address replaces the device are read from the provider's and Proxmox's source.

None of it has been observed against a real Proxmox VE. Nothing here shows that a lease is granted, that a reservation or name matches, that a guest's DHCP client runs, that the connection host reaches the guest, or that anything is reachable after a mode change. [Compatibility](../../../docs/compatibility.md#dhcp-addressing) records that boundary, and your root module's own lock decides which provider build you run.

## Additional network attachments

`additional_network_attachments` adds network attachments after the primary one. The primary attachment is the one the inputs above describe: it is always `net0` and cloud-init IP configuration `0`, and it keeps every input, default, and output it had. Leave the list empty, the default, and the VM plans exactly as before. No additional attachments is written `[]` or by leaving the input out; a null is refused rather than read as an empty list, so that one handed down by a wrapping module cannot become a request to remove what a VM already has.

**Additional attachments can be added and changed on an existing VM, but not taken away.** Read [Changing attachments on an existing VM](#changing-attachments-on-an-existing-vm) and [What is not supported](#what-is-not-supported) before you declare any, because an attachment you add is one you keep.

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
| `ipv4_address_cidr` | Static IPv4 address in dotted decimal with a prefix length from 8 to 32. Null gives the attachment no cloud-init IP configuration of its own. |
| `mac_address` | Unicast MAC address written as six colon-separated hexadecimal octets, used as given. Null lets Proxmox assign one. |

Declared MAC addresses must differ from one another and from the primary attachment's [`network_mac_address`](#the-primary-mac-address), whatever letter case each is written in. That is a rule about what you declare in one configuration, and nothing more. The module does not compare a declared address with one a device already holds, whether Proxmox assigned it or the device kept it after you stopped declaring it, so declaring an address another device of the same VM has is not caught. It promises nothing about uniqueness on your network either.

There is no gateway, and no DHCP. Only the primary attachment can have a gateway, so the guest never receives a second default route from this module, and routing between attachments is guest configuration. An additional attachment's `ipv4_address_cidr` is a static address or null: `dhcp` is rejected, because a DHCP service could hand each such attachment its own default route. OpenTofu ignores a key the type does not declare, without an error. A `gateway` written on an additional attachment does nothing, and neither does a misspelled attribute name: `vlan` for `vlan_id` leaves the device untagged, with no diagnostic. Check the plan for the tag, address, and MAC address you meant.

As with VLAN tags, the module sets the Proxmox side of each attachment and nothing more. It does not check that an address belongs on its bridge or VLAN, and it does not configure interfaces inside the guest.

### Position is identity

An attachment is its position in the list. The first entry is `net1` with cloud-init IP configuration `1`, the next is `net2`, and so on. Seven entries fit, for eight attachments in total, because the provider carries at most eight cloud-init IP configurations.

The guest recognizes an interface by its MAC address: the network data Proxmox generates for cloud-init matches each addressed interface to the MAC address of the device in its slot, and names it `eth` followed by the slot number. `mac_addresses` reports every attachment's MAC address in slot order, `net0` first. In the plan that adds an attachment without `mac_address`, its entry reads `null` rather than a value known after apply; the address Proxmox assigns appears once that apply has run, so read it from a later plan or apply.

An attachment without an address declares no cloud-init IP configuration of its own. That says what this module declares for the slot, not what the VM holds there. Proxmox copies a template's own `ipconfig` entries into every clone, and an entry an earlier address left at a slot stays there, so a device at that slot can still boot with an address you never declared for it. A plan that proposes removing a cloud-init IP configuration you did not declare is showing you one of those. Whether your template carries such entries is yours to know. Nor is an addressless attachment a statement about the guest: what a template's own image does with an interface that cloud-init says nothing about belongs to the template, and to you.

### Changing attachments on an existing VM

Once a VM exists, these are the supported changes. With the provider build this repository locks, none replaces the VM: each plans as `update in-place`, or as no change where the table says so, leaves the primary attachment and its MAC address as they are, and settles, so that once it is applied the next plan proposes nothing.

| Change | What the guest sees |
| --- | --- |
| Add an attachment after the last one, with or without an address | A new device. |
| Change an attachment's `bridge` or `vlan_id` | The same device, with the link interruption described for [VLAN changes](#vlan-tagging). |
| Change a declared `mac_address`, or declare one where Proxmox assigned it | A different device: Proxmox unplugs the old one and plugs in one with the new address. Writing the same address in a different letter case plans as a change too. |
| Stop declaring a `mac_address` | Nothing. The device keeps the address it has, and the plan shows no change. |
| Change an attachment's address to another address | The slot's cloud-init address changes, with the reboot described below. |
| Give an address to an attachment that has none | The slot gains a cloud-init address, with the reboot described below. |

Existing attachments keep their order, and the list may grow but not shrink.

**Changing any attachment's address reboots the VM.** This covers adding an addressed attachment, changing an address, giving an address to an attachment that had none, and the primary attachment's own `ipv4_address_cidr` and [`ipv4_mode`](#switching-an-existing-vm-between-static-and-dhcp). Each changes the cloud-init data, and with the locked provider's defaults that rebuilds the cloud-init drive and reboots a running VM. The changed data also gives the VM a new cloud-init instance identifier, so on that boot cloud-init treats the guest as a new instance. It re-applies network configuration and, unless your template's cloud-init configuration says otherwise, deletes and regenerates the guest's SSH host keys. Expect the reboot, and expect host-key verification to change. Adding an attachment without an address leaves the cloud-init data unchanged.

### What is not supported

**Removing an attachment, removing an attachment's address, reordering attachments, clearing the list, and removing an attachment to add it back are not supported.** That holds for every additional attachment, including the last one and one that never had an address.

The module cannot stop you. Input validation sees only the configuration you give it now, not the order, count, or addresses the VM had before, so an unsupported change is not rejected: it plans as an ordinary `update in-place`. That plan is not evidence that the change is safe. Reading the plan before you apply is the control, and it is yours.

Two behaviours of the locked provider are the reason.

- **Position is identity, so removing or reordering re-maps slots.** When an entry leaves the middle of the list, or entries change places, each affected slot takes another entry's bridge, VLAN, address, and declared MAC address. A MAC address Proxmox assigned stays with its slot rather than with its entry; a declared one moves with its entry, so the device in that slot is replaced. Either way, an interface the guest knew becomes a different one.
- **A retired address is never removed.** The provider sends Proxmox only the IP configurations that declare something, and never deletes one. When an addressed attachment or an address goes away, its `ipconfig` entry stays in the VM's configuration. Proxmox still generates cloud-init network data for that slot and matches it to whichever device is there now, so a later device can boot with the retired address. The provider also reads the entry back, so every later plan proposes the same in-place update to remove it. Applying that update removes nothing, and it rebuilds the cloud-init drive and reboots a running VM each time.

Some of these changes would settle, such as removing a last attachment whose slot never held an address, or exchanging two attachments that both have one. Which ones do depends on what each slot has held, which the module cannot see and you would have to reconstruct. None of them is supported.

If a plan shows a network device being removed, attachments changing places, or a cloud-init IP configuration being removed, it is one of these changes: do not apply it. Applying it again is not a way out, and neither is hiding the difference or the reboot. If you need fewer attachments or a different order, keep the slots you have, wait for a provider build that is shown to clear retired entries, or plan a deliberate, reviewed replacement of the VM. A replacement destroys the existing VM and everything on its disks.

If a plan shows the VM being replaced for any attachment change, do not apply it either: that is not the behaviour this module relies on. Check which provider build your root module's lock selects, because only the build named below has been evaluated.

### Where this is evidenced

All of the above is for the provider build this repository locks, `bpg/proxmox` v0.111.1, at provider level. Three kinds of evidence stand behind it, and they are not the same thing.

- **Plans.** Credential-free plans made with that build, with refresh disabled, against synthetic prior states: declaring attachments at creation, every supported change in the table, and every unsupported change named above.
- **Modelled read-back.** Each change was then planned again against a state modelled on the provider's read path. That is what "settles" and "never settles" rest on. No apply and no refresh was run.
- **Source.** That an update sends each existing device's MAC address back to Proxmox, sends only the IP configurations that declare something and deletes none, that a read returns every one Proxmox holds, and that an initialization change rebuilds the cloud-init drive and reboots, are read from the provider's source. That Proxmox assigns a MAC address only to a device without one, copies a template's `ipconfig` entries into a clone, and matches cloud-init network data by slot and MAC address is read from Proxmox's.

None of it has been observed against a real Proxmox VE. Nothing here shows that a device is plugged or unplugged successfully, that a device keeps its MAC address at run time, that a guest names, configures, or brings up an interface, that cloud-init re-applies configuration or regenerates host keys on your template, or that anything is reachable or routed through any attachment. [Compatibility](../../../docs/compatibility.md#multiple-network-attachments) records that boundary, and your root module's own lock decides which provider build you run.

## Static IPv6

`ipv6_address_cidr` adds a static IPv6 address to the primary attachment's cloud-init IP configuration, beside its IPv4 configuration, static or [DHCP](#dhcp-addressing), rather than in place of it. Leave it `null`, the default, and the module declares no IPv6 and plans exactly as before. `ipv6_gateway` optionally adds an IPv6 default gateway, global or link-local; it needs the address.

Additional attachments take no IPv6. Their entries have no IPv6 attribute, and like `gateway`, one written there does nothing, with no diagnostic.

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

The global IPv6 addresses come from the [RFC 3849](https://www.rfc-editor.org/info/rfc3849/) documentation prefix, `fe80::1` is a generic link-local address, and none of them names anything real. DNS servers may be IPv4, IPv6, or both, with or without IPv6 addressing, and at least one is still required.

Only static IPv6 is supported. Proxmox also accepts `auto` for stateless autoconfiguration, `dhcp` for DHCPv6, and `manual` in the same field, but cloud-init's renderers do not give the first two one meaning, so the module rejects all three when you plan. If your network relies on either for guests, configure IPv6 inside the guest instead. IPv6-only addressing is not supported either: the primary attachment always has an IPv4 mode, static or DHCP.

The declared IPv6 address never becomes `connection.host` on its own. That stays the declared static IPv4 address, or the `connection_host` you supply, which may be an IPv6 address or a name. Adding IPv6 to an existing VM therefore leaves your inventory as it was.

The module puts the address and gateway into the cloud-init network data and nothing more. For IPv6 to work in the guest, you provide:

- a template whose cloud-init renders a static IPv6 subnet and its gateway;
- the prefix the address comes from, and an address no other host uses;
- routing and upstream IPv6 service on the bridge's network, and router advertisements if you rely on them;
- a gateway that is reachable on that network. When you leave the gateway out, the module makes no claim about where the guest's IPv6 default route comes from. Nothing checks that the address, gateway, and network agree.

**Adding, changing, or removing IPv6 on an existing VM reboots it.** The VM is updated in place rather than replaced, but any change to its cloud-init configuration makes the provider rebuild the cloud-init drive and reboot a running VM. The next boot is a new cloud-init instance: it re-applies the network configuration, and unless your template turns that off it regenerates the guest's SSH host keys, so expect a host-key warning on your next connection. The same is true of a change to the DNS servers.

**Removing the declared address is not a claim that the guest has no IPv6 afterwards.** It removes the address and gateway from the cloud-init network data. Addresses the guest configures for itself, such as link-local ones or those it derives from router advertisements, are outside the declaration.

Read the plan before you apply. An IPv6-only change shows the VM as `update in-place`, with only `initialization` changing. If a plan shows the VM being replaced for an IPv6 change, do not apply it: that is not the behaviour this module relies on.

That in-place behaviour is evidenced for the provider build this repository locks, `bpg/proxmox` v0.111.1, at provider level: its schema and source, and credential-free plans made with that build for adding IPv6 with and without a gateway, changing the address, prefix length, and gateway, adding and removing the gateway, and removing IPv6; for adding, changing, and removing it in DHCP mode and beside an additional attachment, whose configuration stayed as it was; and for switching the IPv4 mode with IPv6 declared. Each was followed by a plan from the state the provider's read would record afterwards, which showed no further change. It has not been observed against a real Proxmox VE, and nothing here shows that a guest configures the address, that the gateway or any route works, that the guest is reachable over IPv6, or that it has no other IPv6 addresses. [Compatibility](../../../docs/compatibility.md#static-ipv6-addressing) records that boundary, and that your own root module's lock decides which provider build you run.

## Limitations

This module is one VM, cloned once, addressed as you declare. It does not do:

- template creation or upkeep;
- disk resizing, extra disks, or any disk management — the clone inherits the template's layout;
- linked clones, or cloning from a template on another node;
- DHCP on an additional attachment, DHCP service, scope, reservation, or name management, or discovering the address a guest was given;
- IPv6 stateless autoconfiguration or DHCPv6, IPv6-only addressing, IPv6 on additional attachments, VLAN trunks, or more than eight network attachments;
- removing, reordering, or taking the address from an additional attachment on an existing VM;
- a gateway or routes on any attachment but the primary, NIC models, firewall, MTU, rate, queue, or link-state settings;
- VLAN creation, bridge configuration or discovery, or network configuration inside the guest;
- guest packages, services, users, authorized keys, or SSH configuration after cloud-init;
- LXC containers, HA, pools, or firewall rules.

## How this module is checked

Formatting, `tofu validate`, and a set of contract tests under [`tests/`](tests) that run against a **mocked** provider: no Proxmox endpoint, no credentials, nothing created. Run them with `task validate:tofu`, or directly as [Local validation](../../../docs/validation.md) describes.

They prove what the module asks the provider for — one full clone of the declared template, the declared static addressing and bootstrap account, the guest-agent channel attached by default and absent when it is turned off, waiting for an agent-reported address disabled in both cases, `stop_on_destroy` on both settings reaching the resource, the `connection` output's derivation, the network device left untagged by default and tagged with `1` and `4094` without gaining a second device or changing the addressing or `connection` output, no additional attachment by default, additional attachments in the declared order from `net1` with their own bridge, tag, address, and MAC address, no gateway on any of them, an empty IP configuration for an addressless attachment before an addressed one and none after the last addressed one, eight attachments accepted, undeclared and distinct declared MAC addresses accepted together, `mac_addresses` in slot order, and the primary attachment and `connection` output unchanged by them, static as the default addressing mode, DHCP declared on the primary IP configuration with no address or gateway and the DNS servers kept, additional attachments left static beside it, the connection host published in either mode and the declared address otherwise, the primary MAC address absent by default and reaching `net0` as given in either mode, and reported first in `mac_addresses`, IPv6 absent by default and, when declared, its address and global or link-local gateway reaching the primary IP configuration beside the static or DHCP IPv4 one without changing the `connection` output or reaching an additional attachment, a supplied IPv6 connection host published beside it, and IPv6 DNS servers accepted beside IPv4 ones — and that bad input fails at plan time, including a null in place of the attachment list, one MAC address declared twice in either letter case, on two additional attachments or on the primary and an additional one, and every rejected combination of mode, address, gateway, and connection host.

They prove nothing about a real Proxmox VE. No clone, boot, cloud-init run, SSH connection, shutdown, stop, destroy, VLAN change, attachment change, DHCP lease, IPv6 change, or guest agent has been exercised. Nor can a mocked provider show that a tag, attachment, addressing-mode, MAC address, or IPv6 change is made in place, or that a plan settles afterwards; [VLAN tagging](#vlan-tagging), [Additional network attachments](#where-this-is-evidenced), [DHCP addressing](#where-the-dhcp-behaviour-is-evidenced), and [Static IPv6](#static-ipv6) say where that evidence comes from. [Compatibility](../../../docs/compatibility.md) records what this evidence does and does not cover.

`.terraform.lock.hcl` is committed so those checks resolve the same provider build every time, verified against recorded hashes, on Linux and macOS. It governs this repository's own validation. Your root module has its own lock file; this one does not constrain it.
