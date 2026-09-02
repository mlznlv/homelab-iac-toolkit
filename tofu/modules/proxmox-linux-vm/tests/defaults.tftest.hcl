# Contract evidence for the module's default behaviour.
#
# The provider is mocked, so these runs need no Proxmox endpoint, credential,
# or network access and create nothing. They prove what the module asks the
# provider for and what it publishes as outputs. They prove nothing about a
# live Proxmox VE, a clone, cloud-init, SSH, a guest agent, or a destroy.

# Every value below is fictional or reserved for documentation. The SSH key is
# a throwaway public key generated for these fixtures; nothing holds its
# private half.

mock_provider "proxmox" {}

variables {
  name              = "fictional-vm"
  node_name         = "fictional-node"
  template_id       = 9000
  datastore_id      = "fictional-datastore"
  cpu_cores         = 2
  memory_mib        = 2048
  network_bridge    = "vmbr0"
  ipv4_address_cidr = "192.0.2.10/24"
  ipv4_gateway      = "192.0.2.1"
  dns_servers       = ["192.0.2.53", "192.0.2.54"]
  username          = "fictional"
  ssh_public_keys   = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"]
}

run "one_full_clone_of_the_declared_template" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.this.clone[0].vm_id == 9000
    error_message = "The VM must be cloned from the declared template_id."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.clone[0].full
    error_message = "The clone must be a full clone, so the VM does not depend on the template."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.clone[0].datastore_id == "fictional-datastore"
    error_message = "The clone must land on the declared datastore."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.name == "fictional-vm"
    error_message = "The VM must carry the declared name."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.node_name == "fictional-node"
    error_message = "The VM must be created on the declared node."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.cpu[0].cores == 2
    error_message = "The VM must be sized with the declared number of CPU cores."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.memory[0].dedicated == 2048
    error_message = "The VM must be sized with the declared dedicated memory."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 1
    error_message = "The module attaches exactly one network device."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].bridge == "vmbr0"
    error_message = "The network device must be attached to the declared bridge."
  }
}

run "static_addressing_and_bootstrap_access" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24"
    error_message = "Addressing must be the declared static IPv4 CIDR rather than DHCP."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "The declared IPv4 gateway must reach cloud-init."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].dns[0].servers == tolist(["192.0.2.53", "192.0.2.54"])
    error_message = "The declared DNS servers must reach cloud-init in the declared order."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].user_account[0].username == "fictional"
    error_message = "The bootstrap account must use the declared username."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].user_account[0].keys) == 1
    error_message = "The declared SSH public keys must reach the bootstrap account."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].datastore_id == "fictional-datastore"
    error_message = "The cloud-init drive must land on the declared datastore."
  }
}

run "guest_agent_integration_is_disabled_by_default" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.this.agent[0].enabled == false
    error_message = "Provider-side guest-agent integration must be off unless the consumer enables it."
  }
}

run "destroy_stops_the_vm_by_default" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.this.stop_on_destroy == true
    error_message = "stop_on_destroy must default to true, so destroy does not depend on guest shutdown."
  }
}

run "connection_output_is_derived_from_the_declared_values" {
  command = plan

  assert {
    condition     = output.connection.host == "192.0.2.10"
    error_message = "connection.host must be the declared IPv4 address without its prefix length."
  }

  assert {
    condition     = output.connection.user == "fictional"
    error_message = "connection.user must be the bootstrap username."
  }

  assert {
    condition     = output.connection.port == 22
    error_message = "connection.port must default to 22."
  }
}
