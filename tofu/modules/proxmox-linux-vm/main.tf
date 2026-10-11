# One Proxmox Linux VM, full-cloned from a consumer-supplied cloud-init
# template.
#
# The provider is required in versions.tf and configured by the consumer: this
# module declares no provider block and no backend, so a root module keeps
# ownership of endpoints, credentials, and state.

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
  # is the declared configuration, never an agent-reported address.
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
  # so null is the one way to say untagged. A null MAC address leaves the
  # choice to Proxmox.
  network_device {
    bridge      = var.network_bridge
    vlan_id     = var.network_vlan_id
    mac_address = var.network_mac_address
  }

  # Bootstrap only. These values give the consumer a way in to the new guest;
  # they do not make this module the continuing owner of guest users,
  # authorized keys, or SSH configuration.
  initialization {
    datastore_id = var.datastore_id

    # DHCP is declared explicitly rather than left out: Proxmox falls back to
    # DHCP for an interface with no IP configuration, but the module keeps the
    # primary configuration declared in both modes. The gateway is null in
    # DHCP mode, so the provider sends none.
    ip_config {
      ipv4 {
        address = var.ipv4_mode == "dhcp" ? "dhcp" : var.ipv4_address_cidr
        gateway = var.ipv4_gateway
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

  # Checks that span more than one input. They fail at plan time, before
  # anything reaches Proxmox.
  lifecycle {
    precondition {
      condition     = var.ipv4_mode != "static" || (var.ipv4_address_cidr != null && var.ipv4_gateway != null)
      error_message = "Static IPv4 addressing, the default ipv4_mode, needs both ipv4_address_cidr and ipv4_gateway."
    }

    precondition {
      condition     = var.ipv4_mode != "dhcp" || (var.ipv4_address_cidr == null && var.ipv4_gateway == null)
      error_message = "With ipv4_mode = \"dhcp\", ipv4_address_cidr and ipv4_gateway must be null: the DHCP service supplies the address, and Proxmox expects no gateway alongside DHCP."
    }

    precondition {
      condition     = var.ipv4_mode != "dhcp" || var.connection_host != null
      error_message = "With ipv4_mode = \"dhcp\", connection_host is required, because the module cannot know the address the DHCP service will grant and never discovers one."
    }
  }
}
