# Contract evidence that root's SSH public keys are creation-time bootstrap.
#
# The provider is mocked: the apply below creates nothing, and its only purpose
# is to give the following runs a prior state to plan against. These runs prove
# that the module declines to act on a later key change. They do not prove what
# the provider would otherwise do with one; the provider-level evidence
# recorded with the implementation does that.

# Every value below is fictional or reserved for documentation. The SSH keys
# are throwaway public keys generated for these fixtures; nothing holds their
# private halves.

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
  dns_search_domain       = "example.invalid"
  ssh_public_keys         = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"]
}

run "the_declared_keys_reach_the_container_at_creation" {
  command = apply

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].user_account[0].keys == tolist(["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"])
    error_message = "The declared root SSH public keys must reach the container when it is created."
  }
}

run "a_replaced_key_changes_nothing_on_the_existing_container" {
  command = plan

  variables {
    ssh_public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6TfODVI+8oJLuI2I9rUoAhzQQuNG8odrVeJMibl4uz other@example.invalid"]
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].user_account[0].keys == tolist(["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"])
    error_message = "A later key change must leave the container's bootstrap keys as they were created."
  }
}

run "an_added_key_changes_nothing_on_the_existing_container" {
  command = plan

  variables {
    ssh_public_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6TfODVI+8oJLuI2I9rUoAhzQQuNG8odrVeJMibl4uz other@example.invalid",
    ]
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.initialization[0].user_account[0].keys) == 1
    error_message = "A key added after creation must not reach the existing container."
  }
}

# The keys are the one thing the module declines to act on after creation.
# Every other input must still reach the plan when it changes, including the
# two changes that are not supported: a changed value is shown, never hidden.
run "every_other_changed_input_still_reaches_the_plan" {
  command = plan

  variables {
    name                    = "renamed-container.example.invalid"
    root_filesystem_size_gb = 32
    cpu_cores               = 4
    memory_mib              = 4096
    network_bridge          = "vmbr1"
    ipv4_address_cidr       = "192.0.2.30/24"
    ipv4_gateway            = "192.0.2.254"
    dns_servers             = ["192.0.2.54"]
    dns_search_domain       = "search.test"
    nesting_enabled         = false
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].hostname == "renamed-container.example.invalid"
    error_message = "A changed name must reach the plan."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.disk[0].size == 32 && proxmox_virtual_environment_container.this.cpu[0].cores == 4 && proxmox_virtual_environment_container.this.memory[0].dedicated == 4096
    error_message = "A changed root filesystem size, core count, and memory must reach the plan."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.network_interface[0].bridge == "vmbr1" && proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.30/24" && proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.254"
    error_message = "A changed bridge, address, and gateway must reach the plan."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].dns[0].servers == tolist(["192.0.2.54"]) && proxmox_virtual_environment_container.this.initialization[0].dns[0].domain == "search.test"
    error_message = "Changed DNS servers and a changed search domain must reach the plan."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.features[0].nesting == false
    error_message = "A changed nesting value must be shown in the plan, not concealed, even though applying it is not supported."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].user_account[0].keys == tolist(["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"])
    error_message = "The bootstrap keys must stay as they were created while everything else changes."
  }
}
