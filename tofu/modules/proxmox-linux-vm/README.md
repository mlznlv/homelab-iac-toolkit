# `proxmox-linux-vm`

Create one full-clone Linux VM from a consumer-supplied cloud-init template. The module owns its
Proxmox lifecycle and initial access bootstrap. Provider configuration, backend/state, templates
and continuing guest configuration are consumer-owned. See [Using the
toolkit](../../../docs/using.md).

## Requirements

Read [Compatibility](../../../docs/compatibility.md), especially the **known VM CLI-minimum
failure**, before selecting a CLI. Executable requirements are in [`versions.tf`](versions.tf);
your root lock selects the provider build.

Supply a template on the target node whose cloud-init handles your selected addressing, DNS,
username and SSH public keys. Additional addressed interfaces must be matched by MAC; DHCP needs
a functioning DHCPv4 renderer/client; static IPv6 needs its address/gateway renderer. The
template need not contain the agent.

The clone inherits template disks and configuration. The template or Proxmox's default chooses
cloud-init format and per-instance package upgrade behavior; the template's default-user
configuration chooses bootstrap groups/sudo rules. The module supplies no VM DNS search-domain
input: template/node inheritance still applies. [ADR 0019](../../../docs/decisions/0019-explicit-vm-dns-search-domain.md)
is accepted for later implementation; the input is not available yet.

You supply bridges, VLAN transport/switching/routing, suitable addresses and DNS; DHCP
service/reservations/naming; IPv6 prefix allocation, uniqueness, routing, upstream service and
any router advertisements; and SSH private keys. The module cannot check that an address/gateway
belongs on a bridge or VLAN.

## Quick start

In a consumer root using your pinned checkout:

```hcl
module "fictional_vm" {
  source = "./vendor/proxmox-iac-toolkit/tofu/modules/proxmox-linux-vm"

  name           = "fictional-vm"
  node_name      = "fictional-node"
  template_id    = 9000
  datastore_id   = "fictional-datastore"
  cpu_cores      = 2
  memory_mib     = 2048
  network_bridge = "vmbr0"

  ipv4_address_cidr = "192.0.2.10/24"
  ipv4_gateway      = "192.0.2.1"
  dns_servers       = ["192.0.2.53"]
  username          = "fictional"
  ssh_public_keys   = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
}
```

Values are fictional. Supply provider/backend configuration, then follow the [reviewed-plan
workflow](../../../docs/using.md#workflow).

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
| `ipv4_address_cidr` | `string` | Static IPv4 address with a prefix length, such as `192.0.2.10/24`. Required in static mode, the default; must be null with [DHCP](#dhcp-addressing). |
| `ipv4_gateway` | `string` | IPv4 default gateway, without a prefix length. Required in static mode; must be null with DHCP. |
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
| `network_vlan_id` | `number` | `null` | Access VLAN tag for the primary network device, `1` to `4094`. Null leaves it untagged. |
| `ipv4_mode` | `string` | `"static"` | IPv4 addressing mode of the primary attachment: `"static"` or `"dhcp"`. |
| `connection_host` | `string` | `null` | Host published in the `connection` output: a hostname or an IPv4 or IPv6 address. Required with DHCP. Metadata only. |
| `network_mac_address` | `string` | `null` | MAC address for the primary network device, `net0`. Null lets Proxmox assign one. |
| `additional_network_attachments` | `list(object)` | `[]` | Up to seven more network attachments, `net1` onwards, in the order given. On an existing VM they can be added and changed, not removed or reordered. |
| `ipv6_address_cidr` | `string` | `null` | Static IPv6 address with a prefix length from `8` to `128`, such as `2001:db8::10/64`, added to the primary attachment beside its IPv4 addressing. Null declares no IPv6. |
| `ipv6_gateway` | `string` | `null` | IPv6 default gateway, global or link-local, without a prefix length. Needs `ipv6_address_cidr`. |

Locally decidable invalid inputs fail before apply. Numeric ranges, DNS-label names, key syntax,
address families/prefixes, modes, conditional requirements, and duplicate declared IP/MAC
addresses are checked in [`variables.tf`](variables.tf) and [`main.tf`](main.tf). Runtime
prerequisites remain the consumer's responsibility.

## Outputs

| Output | Value |
| --- | --- |
| `connection` | `{ host, user, port }`: supplied `connection_host`, otherwise static IPv4 without prefix; bootstrap username; `ssh_port` |
| `mac_addresses` | All declared/provider-assigned MACs in slot order, `net0` first |
| `vm_id` | Supplied or assigned VM identifier |
| `vm_name` | Declared name |

All are non-sensitive. `connection` is metadata: it configures no SSH service, resolves no
hostname, discovers no address and proves no reachability. Declared IPv6 never becomes `host`
automatically. Map values into ordinary inventory under
[Using](../../../docs/using.md#workflow); no component reads them at runtime.

## Network examples

These are input fragments to add to the complete call above.

### VLAN tagging

```hcl
network_vlan_id = 42
```

`null` means untagged while keeping the device attached. Only whole tags 1–4094 are accepted;
provider sentinel `0` is not public. No VLAN/bridge creation, trunking or guest VLAN interface
is configured.

### DHCP addressing

Replace the static IPv4 inputs with:

```hcl
ipv4_mode           = "dhcp"
connection_host     = "fictional-vm.example.invalid"
network_mac_address = "00:00:5E:00:53:01"
```

Static mode requires address and gateway; DHCP requires both null and an explicit connection
host. DNS servers remain required in both. A connection host may be a hostname or plain
IPv4/IPv6 literal, without scheme, brackets or port. Ambiguous IPv4 spellings such as
leading-zero octets or hexadecimal are rejected.

For a reservation effective at first boot, declare a MAC and create the reservation before
apply. Otherwise Proxmox assigns one and publishes it later. Apply waits for neither a lease nor
an agent. Additional attachments remain static or addressless, avoiding multiple DHCP-supplied
default routes.

### Static IPv6

```hcl
ipv6_address_cidr = "2001:db8::10/64"
ipv6_gateway      = "fe80::1"
dns_servers       = ["2001:db8::53", "192.0.2.53"]
```

IPv6 is optional beside either primary IPv4 mode. The address requires a prefix 8–128; a global
or link-local gateway is optional but requires the address. `auto`, `dhcp`, `manual`, IPv6-only
and additional-attachment IPv6 are unsupported. Without a gateway the module makes no
default-route claim. Removing declared IPv6 does not remove guest-configured link-local or
router-advertisement addresses.

### Additional network attachments

```hcl
additional_network_attachments = [
  { bridge = "vmbr1", vlan_id = 42, ipv4_address_cidr = "198.51.100.10/24" },
  { bridge = "vmbr2", mac_address = "00:00:5E:00:53:02" },
]
```

| Attribute | Contract |
| --- | --- |
| `bridge` | Required bridge |
| `vlan_id` | Optional access tag; same rules as primary |
| `ipv4_address_cidr` | Optional dotted-decimal static IPv4, prefix 8–32; null declares no IP configuration |
| `mac_address` | Optional unicast MAC, six colon-separated hex octets; passed unchanged |

Position is identity: entries map to `net1` onwards with matching cloud-init slots, at most
seven additions/eight attachments total. Proxmox network data matches addressed devices by MAC
and names them `eth<slot>`. An undeclared MAC can appear as null in the first plan; read the
assigned value after apply. Declared MAC uniqueness is case-insensitive across all attachments;
assigned, retained and network-wide collisions cannot be checked locally.

Only the primary has a gateway. Extra object keys are silently discarded by OpenTofu: `gateway`,
IPv6 fields or a typo such as `vlan` do nothing. Review the actual planned fields. Addressless
means no configuration declared by this module: inherited template `ipconfig` entries, earlier
slot addresses or guest configuration may still supply one.

## Lifecycle

These are provider-level expectations, not observed live behavior; the exact build and evidence
are in [Compatibility](../../../docs/compatibility.md#provider-lifecycle-evidence). Read every
plan before explicit apply. Unexpected replacement for a supported update is a stop condition
requiring provider/Architecture review.

| Change | Contract and consequence |
| --- | --- |
| Add/change/remove a VLAN; change bridge | In-place; running link detaches/re-attaches and interrupts connectivity |
| Append an additional attachment | In-place; new device; existing slots/primary MAC preserved |
| Change or first declare a MAC | In-place VM update; old device is unplugged and a different one appears; old reservations stop matching |
| Remove a MAC declaration | Retains the current address; no change. Case-only edits can still plan a device change |
| Add/change an attachment address; switch static/DHCP | In-place; initialization consequences below |
| Add/change/remove primary IPv6 or change DNS | In-place; initialization consequences below |
| Change only connection host/port | Output only; no infrastructure change |
| Change source template | Replacement destroys the VM and its disks |

Initialization changes rebuild cloud-init and reboot a running VM on the pinned path. Changed
data creates a new cloud-init instance: network configuration is reapplied and SSH host keys may
be regenerated unless the template disables it. Review package-upgrade/default-user behavior
too. Update dependent addresses, DNS records, inventory and known host keys. An addressless
appended device alone leaves cloud-init data unchanged. Supported updates must converge to a
subsequent no-change plan; an initial in-place plan alone is insufficient evidence.

### Attachment retirement is unsupported

Do not remove/reorder attachments, clear the list, remove an existing address, or remove then
re-add a device, including an addressless final device. Current input validation cannot see
history, so these can plan as ordinary in-place updates. **Reject plans removing devices/IP
configurations or remapping slots.**

The provider leaves retired `ipconfigN` entries and reads them back, causing recurring
differences and repeated cloud-init rebuild/reboot requests. A later device can inherit a
retired address. Assigned MACs stay with slots; declared MACs move with reordered entries. A
removal relinquishes its MAC and re-addition promises neither reuse nor a different value. Even
cases that happen to settle remain excluded uniformly.

Repeated apply, ignored differences, disabled reboot or direct API cleanup are not remedies.
Keep slots, wait for an evidenced provider remedy, or plan a deliberate reviewed replacement
with data preservation. Replacement destroys the old VM and disks. [ADR
0014](../../../docs/decisions/0014-additional-attachment-retirement-lifecycle.md) explains the
restriction and the evidence needed to change it.

### Guest agent and destroy

The channel is attached by default and provider IP waiting is always disabled. Create the VM,
compose inventory, then run the [guest-agent
role](../../../ansible/roles/qemu_guest_agent/README.md); no second apply or power cycle is
needed. Opting out creates a VM where the agent cannot run; attaching the channel later requires
stop/start, because it is not hot-plugged.

Before the agent runs, shutdown/reboot probe it for three seconds, warn and fall back to ACPI;
queries report unavailable. Backups skip filesystem freeze and are crash-consistent rather than
filesystem-consistent. Close this window before relying on agent-dependent operations or
filesystem-consistent backups.

`stop_on_destroy = true` stops the VM without ACPI/agent dependence and can lose unwritten data
or interrupt workloads. `false` requests shutdown via ACPI before the agent runs, or via the
agent afterwards; it can block or time out. Choose that override only when accepting this
trade-off. Destroy remains destructive.

## Limitations and validation

No template acquisition, linked/cross-node clones, disk mutation, DHCP service or address
discovery, extra gateways/routes, configurable NIC models, firewall, MTU/rate/queue/link state,
guest network management, HA or pools are included. Continuing packages, users, keys and SSH
configuration belong to the consumer. For containers use the [separate
module](../proxmox-linux-container/README.md).

[`tests/`](tests) checks declarations and invalid inputs with a mocked provider;
[`versions.tf`](versions.tf) and the repository lock govern those checks.
[Contributing](../../../CONTRIBUTING.md#validate-your-change) owns commands and required
evidence; [Compatibility](../../../docs/compatibility.md#current-evidence-level) owns what has
been established. The module lock does not constrain your root lock.
