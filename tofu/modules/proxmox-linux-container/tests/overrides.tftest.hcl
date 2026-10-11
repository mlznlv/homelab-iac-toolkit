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

  assert {
    condition     = output.container_id == 250
    error_message = "The container_id output must publish the container's identifier."
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

  # A mock cannot show that nothing is planned for the container: the
  # provider-level plan recorded with the implementation does that. This pins
  # the declared values the port could most plausibly have reached.
  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].hostname == "fictional-container.example.invalid" && proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.20/24" && length(proxmox_virtual_environment_container.this.network_interface) == 1
    error_message = "Changing connection metadata must not change the container's hostname, addressing, or interface."
  }

  assert {
    condition     = output.connection.host == "192.0.2.20" && output.connection.user == "root"
    error_message = "Changing the port must leave the published host and user as they were."
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

# Rejections alone would not notice a rule that had become too strict, so each
# range is also exercised at its limits.
run "the_lower_limit_of_each_range_is_accepted" {
  command = plan

  variables {
    name                    = "a"
    container_id            = 100
    root_filesystem_size_gb = 1
    cpu_cores               = 1
    memory_mib              = 16
    ipv4_address_cidr       = "192.0.2.0/8"
    ssh_port                = 1
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].hostname == "a" && proxmox_virtual_environment_container.this.vm_id == 100
    error_message = "A one-character name and the lowest identifier must be accepted."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.disk[0].size == 1 && proxmox_virtual_environment_container.this.cpu[0].cores == 1 && proxmox_virtual_environment_container.this.memory[0].dedicated == 16
    error_message = "The smallest root filesystem, core count, and memory must be accepted."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.0/8" && output.connection.port == 1
    error_message = "An octet of 0, a prefix length of 8, and port 1 must be accepted."
  }
}

run "the_upper_limit_of_each_range_is_accepted" {
  command = plan

  variables {
    name              = "a01234567890123456789012345678901234567890123456789012345678901.a01234567890123456789012345678901234567890123456789012345678901.a01234567890123456789012345678901234567890123456789012345678901.b012345678901234567890123456789012345678901234567890123456789"
    container_id      = 999999999
    cpu_cores         = 128
    ipv4_address_cidr = "203.0.113.255/32"
    ipv4_gateway      = "203.0.113.255"
    dns_servers       = ["203.0.113.255"]
    ssh_port          = 65535
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.initialization[0].hostname) == 253
    error_message = "A 253-character name made of 63-character labels must be accepted."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.vm_id == 999999999 && proxmox_virtual_environment_container.this.cpu[0].cores == 128
    error_message = "The highest identifier and core count must be accepted."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address == "203.0.113.255/32" && proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].gateway == "203.0.113.255" && output.connection.port == 65535
    error_message = "An octet of 255, a prefix length of 32, and port 65535 must be accepted."
  }
}
