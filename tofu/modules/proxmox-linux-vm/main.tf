# One Proxmox Linux VM, full-cloned from a consumer-supplied cloud-init
# template.
#
# The provider is required in versions.tf and configured by the consumer: this
# module declares no provider block and no backend, so a root module keeps
# ownership of endpoints, credentials, and state.

locals {
  # Cloud-init IP configurations are positional like the devices, so an
  # addressless attachment before an addressed one keeps its index with an
  # empty entry. None is declared after the last addressed slot: the provider
  # reads configurations back only up to the last one Proxmox holds, so a
  # trailing empty entry would never match its state.
  additional_ip_config_count = max(0, [
    for index, attachment in var.additional_network_attachments : index + 1
    if attachment.ipv4_address_cidr != null
  ]...)

  # Each declared IPv4 address without its prefix length, in canonical form,
  # so that one address declared with two prefixes is still one address.
  declared_ipv4_addresses = [
    for cidr in concat(
      [var.ipv4_address_cidr],
      [for attachment in var.additional_network_attachments : attachment.ipv4_address_cidr if attachment.ipv4_address_cidr != null],
    ) : try(cidrhost("${split("/", cidr)[0]}/32", 0), cidr)
  ]
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  vm_id     = var.vm_id
  node_name = var.node_name

  # A full clone copies the template's disks instead of referencing them, so
  # the created VM does not depend on the template's continued existence. The
  # disk layout is inherited from the template; this module does not manage
  # disks. The source template must already be on var.node_name, because the
  # module does not expose the provider's cross-node clone argument.
  clone {
    vm_id        = var.template_id
    datastore_id = var.datastore_id
    full         = true
  }

  # The channel is attached at creation, because Proxmox only adds the
  # org.qemu.guest_agent.0 device when this is enabled, and a guest whose
  # qemu-guest-agent service is bound to that device cannot start it before the
  # device exists. Installing the agent itself belongs to Ansible.
  #
  # Waiting is disabled unconditionally rather than exposed: an attached
  # channel with no agent behind it is inert, but a provider that waits for one
  # would block every apply and refresh until its timeout expired. Addressing
  # is the declared static configuration, never an agent-reported address.
  agent {
    enabled = var.guest_agent_enabled

    wait_for_ip {
      disabled = true
    }
  }

  # Destroy stops the VM by default rather than asking the guest to shut down,
  # so it does not depend on ACPI, nor on a guest agent that may not be running
  # yet: the channel is attached from creation, but nothing answers on it until
  # the agent is installed. See the README for the trade-off both values carry,
  # and for which side of that line a shutdown falls on.
  stop_on_destroy = var.stop_on_destroy

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mib
  }

  # A null tag leaves vlan_id unset, which the provider plans as its untagged
  # default. The provider spells that default 0; the module does not accept 0,
  # so null is the one way to say untagged.
  network_device {
    bridge  = var.network_bridge
    vlan_id = var.network_vlan_id
  }

  # Additional attachments follow the primary in the declared order, net1
  # onwards. The provider identifies a device only by its position, and deletes
  # any slot beyond the end of this list. A null MAC address leaves the choice
  # to Proxmox.
  dynamic "network_device" {
    for_each = var.additional_network_attachments

    content {
      bridge      = network_device.value.bridge
      vlan_id     = network_device.value.vlan_id
      mac_address = network_device.value.mac_address
    }
  }

  # Bootstrap only. These values give the consumer a way in to the new guest;
  # they do not make this module the continuing owner of guest users,
  # authorized keys, or SSH configuration.
  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.ipv4_address_cidr
        gateway = var.ipv4_gateway
      }
    }

    # Only the primary attachment has a gateway, so the guest never receives
    # more than one default route.
    dynamic "ip_config" {
      for_each = slice(var.additional_network_attachments, 0, local.additional_ip_config_count)

      content {
        dynamic "ipv4" {
          for_each = ip_config.value.ipv4_address_cidr == null ? [] : [ip_config.value.ipv4_address_cidr]

          content {
            address = ipv4.value
          }
        }
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      username = var.username
      keys     = var.ssh_public_keys
    }
  }

  lifecycle {
    precondition {
      condition     = length(distinct(local.declared_ipv4_addresses)) == length(local.declared_ipv4_addresses)
      error_message = "Every network attachment must have a different IPv4 address. The primary ipv4_address_cidr and each additional attachment's ipv4_address_cidr are compared without their prefix lengths."
    }
  }
}
