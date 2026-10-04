# Contract evidence for the default container behavior.
# The provider is mocked: these tests create nothing and prove no live behavior.

mock_provider "proxmox" {}

variables {
  name                    = "fictional-container.example.invalid"
  node_name               = "fictional-node"
  template_file_id        = "fictional-storage:vztmpl/debian-13-standard_13.0-1_amd64.tar.zst"
  datastore_id            = "fictional-datastore"
  root_filesystem_size_gb = 16
  cpu_cores               = 2
  memory_mib              = 2048
  network_bridge          = "vmbr0"
  ipv4_address_cidr       = "192.0.2.20/24"
  ipv4_gateway            = "192.0.2.1"
  dns_servers             = ["192.0.2.53", "192.0.2.54"]
  ssh_public_keys         = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"]
}

run "container_identity_and_platform_are_explicit" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_container.this.node_name == "fictional-node"
    error_message = "The container must be created on the declared node."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.unprivileged == true
    error_message = "The first reusable container capability must always be unprivileged."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.start_on_boot == true
    error_message = "The module must explicitly start the container after a host boot."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.operating_system[0].template_file_id == "fictional-storage:vztmpl/debian-13-standard_13.0-1_amd64.tar.zst"
    error_message = "The declared template must reach the container resource."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.operating_system[0].type == "debian"
    error_message = "The operating-system type must be Debian rather than the provider's unmanaged default."
  }
}

run "resource_sizing_and_nesting_are_declared" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_container.this.cpu[0].cores == 2
    error_message = "The declared CPU core count must reach the resource."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.memory[0].dedicated == 2048
    error_message = "The declared dedicated memory must reach the resource."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.disk[0].datastore_id == "fictional-datastore" && proxmox_virtual_environment_container.this.disk[0].size == 16
    error_message = "The declared root filesystem datastore and size must reach the resource."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.features[0].nesting == true
    error_message = "Nesting must default to enabled."
  }
}

run "network_dns_and_key_only_bootstrap_are_declared" {
  command = plan

  assert {
    condition     = length(proxmox_virtual_environment_container.this.network_interface) == 1
    error_message = "The module must create exactly one network interface."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.network_interface[0].name == "veth0" && proxmox_virtual_environment_container.this.network_interface[0].bridge == "vmbr0"
    error_message = "The single interface must be veth0 on the declared bridge."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].hostname == "fictional-container.example.invalid"
    error_message = "The declared name must become the container hostname."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.20/24" && proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "The declared static IPv4 address and gateway must reach initialization."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].dns[0].servers == tolist(["192.0.2.53", "192.0.2.54"])
    error_message = "Explicit DNS servers must reach initialization."
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.initialization[0].user_account[0].keys) == 1
    error_message = "The declared root SSH public keys must reach initialization."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].user_account[0].password == null
    error_message = "The module must not configure a root password."
  }
}

run "connection_output_is_declared_metadata" {
  command = plan

  assert {
    condition     = output.connection == { host = "192.0.2.20", user = "root", port = 22 }
    error_message = "The connection output must use the declared IPv4 host, root, and default port 22."
  }

  assert {
    condition     = output.container_name == "fictional-container.example.invalid"
    error_message = "The container_name output must preserve the declared hostname."
  }
}
