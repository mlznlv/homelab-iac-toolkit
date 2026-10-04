# One unprivileged Debian LXC container created from a consumer-supplied
# template. Provider configuration and state remain consumer-owned.

resource "proxmox_virtual_environment_container" "this" {
  node_name    = var.node_name
  vm_id        = var.container_id
  unprivileged = true
  start_on_boot = true

  features {
    nesting = var.nesting_enabled
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mib
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.root_filesystem_size_gb
  }

  network_interface {
    name   = "veth0"
    bridge = var.network_bridge
  }

  initialization {
    hostname = var.name

    ip_config {
      ipv4 {
        address = var.ipv4_address_cidr
        gateway = var.ipv4_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      keys = var.ssh_public_keys
    }
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = "debian"
  }

  lifecycle {
    # The provider treats bootstrap-key changes as replacement-forcing. Keys
    # are creation-time bootstrap only here; continuing key ownership belongs
    # to guest configuration.
    ignore_changes = [initialization[0].user_account[0].keys]
  }
}
