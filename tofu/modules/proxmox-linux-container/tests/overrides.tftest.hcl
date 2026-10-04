# Contract evidence for supported consumer overrides.

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
  dns_servers             = ["192.0.2.53"]
  ssh_public_keys         = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"]
}

run "nesting_can_be_disabled" {
  command = plan

  variables {
    nesting_enabled = false
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.features[0].nesting == false
    error_message = "An explicit nesting_enabled = false must reach the resource."
  }
}

run "a_container_identifier_can_be_supplied" {
  command = plan

  variables {
    container_id = 250
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.vm_id == 250
    error_message = "A declared container_id must reach vm_id."
  }
}

run "ssh_port_changes_connection_metadata_only" {
  command = plan

  variables {
    ssh_port = 2222
  }

  assert {
    condition     = output.connection.port == 2222
    error_message = "connection.port must carry the declared metadata port."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].hostname == "fictional-container.example.invalid"
    error_message = "Changing connection metadata must not change container initialization."
  }
}
