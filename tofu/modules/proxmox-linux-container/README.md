# `proxmox-linux-container`

An OpenTofu module that creates one unprivileged Debian LXC container on Proxmox VE from a container template you already have, gives it one statically addressed network interface and root's bootstrap SSH keys, and publishes where root can be reached.

It is a sibling of [`proxmox-linux-vm`](../proxmox-linux-vm), not a mode of it, and shares no code or interface with it. It owns the container, its root filesystem, and its one network interface in Proxmox and nothing else: it configures no provider, keeps no state, acquires no template, and stops caring about the guest's users, keys, and SSH configuration once the container exists.

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
- a Debian container template volume that already exists on Proxmox storage, with an SSH server that accepts public-key login for root, as the [container template contract](../../../docs/compatibility.md#container-template-contract) describes;
- the node, datastore, bridge, addresses, DNS servers and search domain, sizing, and identifiers below;
- the private half of the SSH keys you authorize, and everything configured inside the container after it is created.

## Usage

```hcl
module "fictional_container" {
  source = "git::https://github.com/mlznlv/proxmox-iac-toolkit.git//tofu/modules/proxmox-linux-container?ref=<commit>"

  name             = "fictional-container.example.invalid"
  node_name        = "fictional-node"
  template_file_id = "fictional-storage:vztmpl/debian-13-standard_13.0-1_amd64.tar.zst"

  datastore_id            = "fictional-datastore"
  root_filesystem_size_gb = 16
  cpu_cores               = 2
  memory_mib              = 2048

  network_bridge    = "vmbr0"
  ipv4_address_cidr = "192.0.2.20/24"
  ipv4_gateway      = "192.0.2.1"
  dns_servers       = ["192.0.2.53"]
  dns_search_domain = "example.invalid"

  ssh_public_keys = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
}
```

Every value above is fictional or reserved for documentation: the addresses come from [RFC 5737](https://www.rfc-editor.org/info/rfc5737/), the name from [RFC 2606](https://www.rfc-editor.org/info/rfc2606/), and none names anything real. Pin `ref` to a commit that contains this module.

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

Values that can be judged without contacting Proxmox are checked when you plan, not when Proxmox rejects them: a name that is not a DNS name or is longer than 64 characters, an address without a prefix length, an IPv6 address in any spelling, an octet written with a leading zero, a gateway carrying a prefix, a DNS server that is not an IPv4 address, a search domain that is empty, a list, or not a DNS name, an empty key list, an entry that is not one OpenSSH public key on one line, a size that is not a whole number within its range, an identifier outside Proxmox's range, and so on.

The name is limited to 64 characters in all, shorter than a DNS name may be. Proxmox writes the whole name as the container's `lxc.uts.name`, and LXC refuses a longer one, so a longer name would give you a container that is created and cannot start. This is read from Proxmox's and LXC's source, not observed.

DNS servers and the search domain are both required, and neither has a default. Proxmox falls back to the node for each of them separately: a container that declares no name server gets the node's, and one that declares no search domain gets the node's `search` line, whatever name servers it declares. A node's resolver settings are not something a reusable module should adopt for you silently, so the module asks for both. `dns_search_domain` is one DNS name, passed to Proxmox as given, and is not derived from the container's name. There is no way to ask for no search domain: an empty domain restores the node fallback instead of switching search off, so that mode is not offered.

## Outputs

| Name | Description |
| --- | --- |
| `connection` | `{ host, user, port }` — the declared IPv4 address without its prefix, `root`, and `ssh_port`. |
| `container_id` | Identifier of the created container, supplied or assigned. |
| `container_name` | The declared hostname. |

All three are non-sensitive; the module never publishes a private key or a password, and never accepts one.

`connection` exists so you can build your own inventory out of values you already declared. `host` is never an address the provider reads back from the running container. `port` configures nothing: the module does not touch the container's SSH service.

## What the module decides for you

Four things are fixed or defaulted by the module rather than left to the provider. For three of them the provider's own default would give you a different container than the inputs describe; the fourth is declared so that it is this module's decision.

- **The operating-system type is Debian.** The provider's default is `unmanaged`, and Proxmox writes the network configuration, hostname, DNS servers, and root's keys into a container only through a managed operating-system type.
- **The container is unprivileged.** The provider's default is privileged. There is no input for it.
- **The container starts when its host boots.** That matches the provider's default, but the module declares it so that it is this module's decision and its tests assert it. There is no input for it, and no startup ordering.
- **Nesting is on unless you turn it off when the container is created.** See below.

Root gets the SSH public keys you declare and no password.

One provider default is left as it is: swap. The module declares dedicated memory only, and the provider then creates the container with no swap, where Proxmox's own default is 512 MiB. Size `memory_mib` with that in mind.

### Nesting

`nesting_enabled` defaults to `true` because a systemd-based Debian guest may need the nesting feature to behave as Proxmox expects, and the provider's default is off. Nesting gives the container a broader profile; set `nesting_enabled = false` when your guest does not need it. A null is treated as the default, not as off.

**It is a creation-time choice. Changing `nesting_enabled` on an existing container is not supported.** Keep the value the container was created with. The module cannot hold you to that, because input validation sees only the configuration you give it now: a changed value plans as an ordinary `update in-place`, and that plan is not evidence that it can be applied. If a plan shows `nesting` changing on an existing container, do not apply it.

The reason is authorization, on the provider build this repository locks. When features change, that build restates every container feature flag in its update request, not only nesting. Proxmox accepts a change to any flag other than nesting only from `root@pam` itself, and counts a flag that was absent and is now stated as off as a change, so it would refuse the update from any other identity, an API token included. This module does not make `root@pam` a requirement, and it does not hide a changed value from the plan either. Creating the container is unaffected: the create request states nesting alone, and only when it is on. All of this is read from the provider's and Proxmox's source; no refusal has been observed.

## Bootstrap keys are creation-time only

`ssh_public_keys` is used once, when the container is created. Changing the list afterwards produces **no plan at all** for the container: not a replacement, not an update, not a no-op diff. The container and root's `authorized_keys` are left exactly as they are.

That is deliberate. The provider treats root's bootstrap keys as replacement-forcing, so acting on a key change would destroy the container and its root filesystem. The module ignores later changes to that one attribute instead. Rotating root's keys is guest configuration, and it is yours.

If you expected OpenTofu to rotate the keys, nothing will happen. That is this module working as designed, not a failed apply.

## Changing an existing container

Read the plan before you apply. With the provider build this repository locks, these are the plans a change produces:

| Change | Plan | What a running container sees |
| --- | --- | --- |
| `network_bridge`, `ipv4_address_cidr`, `ipv4_gateway` | Update in place | The provider reboots it. |
| `dns_servers`, `dns_search_domain` | Update in place | The provider reboots it. |
| `name` | Update in place | The provider reboots it. |
| `memory_mib` | Update in place | The provider reboots it. |
| `cpu_cores` | Update in place | No reboot is requested. |
| `root_filesystem_size_gb`, larger | Update in place | The root filesystem is resized; no reboot is requested for the size alone. |
| `template_file_id`, `datastore_id`, `node_name`, `container_id` | **Replace** | It is destroyed, with its root filesystem, and a new one is created. |
| `ssh_public_keys` | No change | Nothing. |
| `ssh_port` | No change to the container | Nothing; only the `connection` output changes. |

Changing `ipv4_address_cidr` also changes `connection.host`, and changing `name` changes `container_name`. Where no reboot is requested, that is what the provider's update asks for, not a promise that the guest is undisturbed.

**A replacement destroys the container and its root filesystem.** OpenTofu shows it in the plan as `must be replaced`. The module does not hide it and cannot prevent it; your review of the plan is the control. Supplying the identifier the container already has, or removing a supplied identifier, is not a change.

If a plan shows the container being replaced for a change the table lists as an update, do not apply it: that is not the behaviour this module relies on. Check which provider build your root module's lock selects, because only the build named below has been evaluated.

### What is not supported on an existing container

Two changes plan as `update in-place` and are not supported. The module cannot reject either one, because input validation cannot see what the container had before. Reading the plan before you apply is the control, and it is yours.

- **Making the root filesystem smaller.** Growth is the only supported size change. On the locked provider build a smaller `root_filesystem_size_gb` does not plan a replacement, although the provider means it to: it plans an in-place update, and the provider's update then refuses the smaller size and stops before it sends Proxmox any change. If a plan shows the root filesystem size going down, do not apply it. A smaller root filesystem means recreating the container yourself, deliberately, with its data preserved first and the loss of the old container and its root filesystem accepted. The module has no replacement trigger, resize workaround, or recovery step for this.
- **Changing `nesting_enabled`.** See [Nesting](#nesting).

### Reading and destroying

Reading a started container can take up to ten seconds longer than you expect. The provider's read path asks Proxmox for the container's interfaces and waits up to ten seconds for one to report an address; a timeout is logged as a warning rather than returned as an error. That wait is the provider's. The module neither configures it nor uses its result.

Destroy asks Proxmox to shut the container down with forcing already enabled, and a timeout five seconds shorter than the provider's delete timeout, so under the defaults the guest gets 55 seconds before Proxmox stops it and the container is deleted. That can interrupt a running workload and lose whatever the guest had not written to disk. The module has no timeout or destroy-policy input.

## Limitations

This module is one unprivileged Debian container, created once from a template, addressed statically. It does not do:

- template acquisition or upkeep;
- privileged containers, or cloning from another container;
- VLAN tags, more than one network interface, DHCP, or IPv6;
- mount points, bind mounts, device passthrough, or ID mapping;
- container features other than nesting;
- shrinking the root filesystem, or changing nesting, on an existing container;
- a container with no DNS search domain, or with a list of them;
- a swap setting;
- passwords, or a bootstrap account other than root;
- distributions other than Debian;
- a start-on-boot override, startup ordering, protection, HA, or pools;
- timeout or destroy-policy inputs;
- guest packages, services, users, authorized keys, or SSH configuration after creation.

The [`qemu_guest_agent`](../../../ansible/roles/qemu_guest_agent) role does not apply here: a container has no QEMU guest-agent channel.

## How this module is checked

Formatting, `tofu validate`, and a set of contract tests under [`tests/`](tests) that run against a **mocked** provider: no Proxmox endpoint, no credentials, nothing created. Run them with `task validate:tofu`, or directly as [Local validation](../../../docs/validation.md) describes.

They prove what the module asks the provider for — creation from the declared template and never a clone, the Debian operating-system type, unprivileged mode, start-on-boot, nesting on by default and off when it is turned off at creation, the declared sizing and root filesystem with no swap declared, exactly one interface with the declared static addressing, DNS servers and search domain, root's keys with no password, a later key change leaving the declared keys as they were created, the `connection` output's derivation from declared values whatever the provider reports, and none of the capabilities listed under [Limitations](#limitations) — and that bad input fails at plan time.

A mocked provider cannot show which changes replace a container and which update it. The table above is evidenced for the provider build this repository locks, `bpg/proxmox` v0.111.1, at provider level: its schema and source, and credential-free plans made with that build for each row, including the declared search domain in the create and update plans, the key change planning nothing, and the replacement the provider would otherwise force for it. The two unsupported changes are recorded the same way, as the in-place plans they produce. Which changes reboot a running container, what the provider does with a smaller root filesystem when it applies, what Proxmox requires for a feature change, and that a declared search domain is sent, read back, and keeps the node's own out are read from source, because a plan does not show them.

None of this has been observed against a real Proxmox VE. No container has been created, started, read, updated, rebooted, shut down, stopped, or destroyed; no template has been tried; and nothing shows that Proxmox configures a guest's network, DNS, or keys, that nesting is sufficient for a guest's init system, or that SSH is reachable. [Compatibility](../../../docs/compatibility.md#lxc-capability) records that boundary, and your own root module's lock decides which provider build you run.

`.terraform.lock.hcl` is committed so those checks resolve the same provider build every time, verified against recorded hashes, on Linux and macOS. It governs this repository's own validation. Your root module has its own lock file; this one does not constrain it.
