# `proxmox-linux-container`

An OpenTofu module that creates one unprivileged Debian LXC container from a consumer-supplied Proxmox template.

The module owns the container resource, its root filesystem, one network interface, and creation-time bootstrap. It configures no provider or backend and performs no continuing guest configuration.

## Requirements

| Requires | Version |
| --- | --- |
| OpenTofu | 1.6.0 or later |
| Provider | `bpg/proxmox ~> 0.111.0`; this repository locks v0.111.1 |
| Proxmox VE | 9.x |

The consumer supplies the provider configuration, credentials, backend/state, target node, template, datastore, bridge, addressing, sizing, SSH public keys, and all configuration inside the container after creation.

## Usage

~~~hcl
module "fictional_container" {
  source = "git::https://github.com/mlznlv/homelab-iac-toolkit.git//tofu/modules/proxmox-linux-container?ref=<commit>"

  name                    = "fictional-container.example.invalid"
  node_name               = "fictional-node"
  template_file_id        = "fictional-storage:vztmpl/debian-13-standard_13.0-1_amd64.tar.zst"
  datastore_id            = "fictional-datastore"
  root_filesystem_size_gb = 16
  cpu_cores               = 2
  memory_mib              = 2048

  network_bridge    = "vmbr0"
  ipv4_address_cidr = "192.0.2.20/24"
  ipv4_gateway      = "192.0.2.1"
  dns_servers       = ["192.0.2.53"]

  ssh_public_keys = [
    trimspace(file(pathexpand("~/.ssh/id_ed25519.pub"))),
  ]
}
~~~

All values above are fictional or documentation-reserved.

## Contract

The container is:

- created through `proxmox_virtual_environment_container`;
- explicitly Debian and unprivileged;
- configured to start when the Proxmox host boots;
- nested by default, with `nesting_enabled = false` available when a consumer does not need it;
- given one `veth0` interface on the declared bridge with static IPv4 addressing;
- given explicit DNS servers so node-local resolver settings are not copied silently;
- bootstrapped with root SSH public keys and no password.

The module publishes a non-sensitive `connection` object:

~~~text
host → declared IPv4 address without the prefix
user → root
port → ssh_port metadata, default 22
~~~

It never derives the connection host from provider-reported runtime addressing.

## Lifecycle

The public lifecycle contract follows ADR 0010.

Expected in-place changes on the pinned provider include network, DNS, hostname, memory, CPU, nesting, and root-filesystem growth. Network, DNS, hostname, and memory changes may reboot a running container; CPU changes do not. A nesting change is configuration-only and may require a later restart before it is effective.

Changing the template, datastore, node, identifier, or shrinking the root filesystem is replacement-sensitive and can destroy the existing container and root filesystem. Review every OpenTofu plan before applying it.

Bootstrap SSH keys are creation-time input only. Later changes are ignored by this module so a key rotation does not trigger the provider's replacement behavior. Rotate keys through consumer-owned guest configuration instead.

Destroy uses the provider's container shutdown/forced-stop behavior and may interrupt workloads or lose unwritten data.

## Limitations

This first capability does not include:

- privileged containers;
- cloning from another container;
- VLANs, additional interfaces, DHCP, or IPv6;
- mount points or bind mounts;
- device passthrough or ID mapping;
- passwords;
- non-root bootstrap users;
- distributions other than Debian;
- startup ordering or a start-on-boot override;
- container-specific Ansible roles;
- template acquisition.

The template must already exist and contain the software needed for the consumer to reach the container, including an SSH server if SSH is the management path.

## Evidence level

Repository validation is credential-free. Mock-provider tests prove the module contract and validation, not live Proxmox behavior. Provider-level lifecycle evidence for the exact locked build is reviewed separately before merge.

No repository check proves successful container creation, template compatibility, guest networking, SSH reachability, restart behavior, shutdown, forced stop, or destroy against a live environment.
