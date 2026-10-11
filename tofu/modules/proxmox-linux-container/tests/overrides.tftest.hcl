# Contract evidence for supported consumer overrides.
#
# The provider is mocked: these runs create nothing and prove no live behavior.
# Every value below is fictional or reserved for documentation.

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

# A null is not a third spelling of "off": the provider's own default for
# nesting is false, so a null that reached the resource would silently turn the
# documented default around.
run "a_null_nesting_value_keeps_the_default" {
  command = plan

  variables {
    nesting_enabled = null
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.features[0].nesting == true
    error_message = "A null nesting_enabled must leave nesting enabled, not fall through to the provider's default."
  }
}

run "a_null_ssh_port_keeps_the_default" {
  command = plan

  variables {
    ssh_port = null
  }

  assert {
    condition     = output.connection.port == 22
    error_message = "A null ssh_port must publish the default port 22."
  }
}
