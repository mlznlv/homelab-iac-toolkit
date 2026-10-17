# `proxmox-linux-container`

Create one unprivileged Debian LXC from an existing container template, with one
static IPv4 interface and root's bootstrap public keys. This module owns the
container/root filesystem in Proxmox. It is separate from the
[VM module](../proxmox-linux-vm/README.md).

## Requirements

Read [Compatibility](../../../docs/compatibility.md) and the executable
[`versions.tf`](versions.tf). Your root lock selects the provider build.
Supply provider/backend configuration, state custody, template, node/storage,
bridge/addressing/DNS, sizing and SSH authentication under
[Using](../../../docs/using.md#what-you-own).

The template must be a Debian root filesystem recognized by Proxmox's Debian
setup plugin, with an init system that works unprivileged under the selected
nesting setting, and an SSH server accepting root's public-key login. Other
distributions remain outside this module's contract even if Proxmox detects them.
Proxmox re-applies init/network/hostname/DNS/timezone setup on every start;
consider that when managing guest configuration or upgrading its release.

## Quick start

```hcl
module "fictional_container" {
  source = "./vendor/proxmox-iac-toolkit/tofu/modules/proxmox-linux-container"

  name                    = "fictional-container.example.invalid"
  node_name               = "fictional-node"
  template_file_id         = "fictional-storage:vztmpl/debian-13-standard_13.0-1_amd64.tar.zst"
  datastore_id            = "fictional-datastore"
  root_filesystem_size_gb  = 16
  cpu_cores               = 2
  memory_mib              = 2048
  network_bridge          = "vmbr0"
  ipv4_address_cidr        = "192.0.2.20/24"
  ipv4_gateway             = "192.0.2.1"
  dns_servers              = ["192.0.2.53"]
  dns_search_domain        = "example.invalid"
  ssh_public_keys          = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
}
```

Values are fictional. Establish the pinned checkout and follow the
[reviewed-plan workflow](../../../docs/using.md#workflow).

## Inputs

Required:

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | Container hostname. A DNS name of at most 64 characters in all: dot-separated labels of letters, digits, and inner hyphens. |
| `node_name` | `string` | Proxmox node to create the container on. |
| `template_file_id` | `string` | Identifier of the existing Debian container template volume, in `datastore:path` form. |
| `datastore_id` | `string` | Datastore for the root filesystem. |
| `root_filesystem_size_gb` | `number` | Root filesystem size, in gigabytes. It can be grown later, not shrunk. |
| `cpu_cores` | `number` | CPU cores, from 1 to 128. |
| `memory_mib` | `number` | Dedicated memory, in MiB. At least 16. |
| `network_bridge` | `string` | Bridge for the container's single interface, such as `vmbr0`. |
| `ipv4_address_cidr` | `string` | Static IPv4 address with a prefix length from 8 to 32, such as `192.0.2.20/24`. |
| `ipv4_gateway` | `string` | IPv4 default gateway, without a prefix length. |
| `dns_servers` | `list(string)` | IPv4 DNS servers, in order of preference. At least one. |
| `dns_search_domain` | `string` | DNS search domain: one DNS name, such as `example.invalid`. There is no default, and no value that means none. |
| `ssh_public_keys` | `list(string)` | OpenSSH **public** keys installed for root when the container is created. At least one, each a single line; surrounding whitespace is trimmed. |

Optional:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `container_id` | `number` | `null` | Container identifier. Proxmox assigns the next free one when this is null. |
| `nesting_enabled` | `bool` | `true` | Whether to enable the Proxmox nesting feature when the container is created. See [Nesting](#nesting). |
| `ssh_port` | `number` | `22` | Port published in the `connection` output. Metadata only. |

[`variables.tf`](variables.tf) validates locally decidable name, size, identifier,
IPv4 and key syntax before apply. IPv4 uses plain dotted decimal without
leading-zero octets; keys are trimmed single OpenSSH public-key lines. The
64-character hostname limit comes from LXC's `lxc.uts.name` start limit.

Both DNS servers and a single nonempty search domain are required, passed
unchanged and never derived from the hostname. Proxmox independently inherits
each from the node when omitted. Empty restores domain fallback rather than
providing no-search semantics; no empty, list or no-search mode is offered.

## Outputs and fixed behavior

| Output | Value |
| --- | --- |
| `connection` | `{ host, user, port }`: declared IPv4 without prefix, `root`, `ssh_port` |
| `container_id` | Supplied or assigned identifier |
| `container_name` | Declared hostname |

Outputs are non-sensitive and never discover an address. Port is metadata and
configures no SSH service. The module fixes Debian type, unprivileged mode and
start-on-host-boot, with no startup ordering. Root receives keys and no password.
Dedicated memory is explicit; omitted swap uses the provider's zero default
rather than Proxmox's 512 MiB default, so size memory accordingly.

### Nesting

Nesting defaults to true (null also selects the default) for systemd-based
Debian guests that need it. It broadens the container profile; set
`nesting_enabled = false` at creation if your template works without it.

**Keep the creation-time value.** Later toggles are unsupported despite planning
in place. The pinned provider's update restates non-nesting false feature flags;
Proxmox treats absent-to-false as a change and restricts these changes to the
exact `root@pam` identity, not an API token. Creation sends nesting alone when
on. This module adopts no elevated-identity requirement and does not hide toggles.

## Lifecycle

Read every plan before explicit apply. These expectations come from exact-provider
plans and source, not live observations; see
[Compatibility](../../../docs/compatibility.md#provider-lifecycle-evidence).

| Change | Plan and consequence |
| --- | --- |
| Bridge, IPv4 address/gateway, DNS, name, memory | In-place; provider requests reboot of a running container |
| CPU cores | In-place; no reboot requested |
| Root-filesystem growth | In-place resize; no reboot requested for size alone |
| Template, datastore, node, identifier | Replacement destroys the container and root filesystem |
| Bootstrap SSH keys | Ignored after creation; no resource change |
| SSH port | Output only |

A matching assigned/supplied identifier, or removing its declaration while
retaining that identifier, is not a change. Address/name updates change their
corresponding outputs. No-reboot-request is not an availability guarantee.
Unexpected replacement for an update is a stop condition for provider review.

Bootstrap keys are creation-only: the provider otherwise forces replacement on
key changes, so the module ignores this single attribute after creation. Rotate
root's `authorized_keys` through guest configuration; changing the input does
nothing to existing keys and does not signal a failed apply.

**Reject shrinking and post-create nesting changes during plan review.** Both
can plan in place and cannot be rejected by current-input validation alone.
The pinned provider refuses shrinking during update before sending the change.
Smaller storage needs deliberate consumer-owned recreation/data preservation;
there is no automatic replacement trigger, state rewrite, resize workaround or
recovery path. Replacements lose the old root filesystem.

Reading a started container can wait up to ten seconds for an interface address;
timeout warns rather than fails. Outputs do not use that result. Destroy requests
shutdown with forcing enabled and a timeout five seconds shorter than the delete
timeout: 55 seconds under defaults, then forced stop/deletion. Unwritten data
and running workloads can be lost. No timeout/destroy-policy input is exposed.

## Limitations and validation

No template acquisition, cloning, privileged mode, other distributions, VLANs,
multiple interfaces, DHCP/IPv6, mount/bind points, passthrough, ID mapping, features
other than nesting, swap input, passwords/non-root bootstrap, boot override,
protection, HA or pools are included. Continuing packages/services/users/keys/SSH
remain consumer-owned. The QEMU guest-agent role cannot apply to LXC, which has
no QEMU channel.

[`tests/`](tests) asserts module declarations and invalid inputs with a mocked
provider. [Contributing](../../../CONTRIBUTING.md#validate-your-change) owns checks;
[Compatibility](../../../docs/compatibility.md#current-evidence-level) owns evidence
limits. The committed module lock is for repository validation, not your root.
