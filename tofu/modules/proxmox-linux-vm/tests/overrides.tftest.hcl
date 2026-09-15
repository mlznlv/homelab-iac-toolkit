# Contract evidence for the inputs a consumer can change.
#
# The provider is mocked, so these runs need no Proxmox endpoint, credential,
# or network access and create nothing. An override reaching the provider
# configuration is not evidence that Proxmox behaves as the override intends:
# no shutdown, stop, destroy, or guest agent is exercised here.

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
  dns_servers       = ["192.0.2.53"]
  username          = "fictional"
  ssh_public_keys   = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"]
}

run "destroy_can_be_asked_to_shut_the_guest_down_instead" {
  command = plan

  variables {
    stop_on_destroy = false
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.stop_on_destroy == false
    error_message = "An explicit stop_on_destroy = false must reach the provider resource."
  }
}

run "the_guest_agent_channel_can_be_left_off" {
  command = plan

  variables {
    guest_agent_enabled = false
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.agent[0].enabled == false
    error_message = "An explicit guest_agent_enabled = false must reach the provider resource."
  }

  # Waiting is not an input, so turning the channel off must not turn waiting
  # back on: a VM with no channel is exactly where a wait could never finish.
  assert {
    condition     = proxmox_virtual_environment_vm.this.agent[0].wait_for_ip[0].disabled == true
    error_message = "Waiting for an agent-reported address must stay disabled when the channel is off."
  }
}

run "ssh_port_changes_connection_metadata_only" {
  command = plan

  variables {
    ssh_port = 2222
  }

  assert {
    condition     = output.connection.port == 2222
    error_message = "connection.port must carry the declared ssh_port."
  }

  # The guest's SSH service is untouched by this input: the module writes no
  # SSH configuration at all, and the cloud-init bootstrap below is the same
  # as it is with the default port.
  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].user_account[0].username == "fictional"
    error_message = "The bootstrap account must not change with the connection port."
  }
}

run "a_vm_identifier_can_be_supplied" {
  command = plan

  variables {
    vm_id = 199
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.vm_id == 199
    error_message = "A declared vm_id must reach the provider resource."
  }
}

# These runs show the tag reaching the existing network device. They do not
# show that Proxmox applies it, or that the provider changes it in place: that
# is provider behaviour, which a mock cannot exercise.

run "the_lowest_vlan_identifier_tags_the_existing_network_device" {
  command = plan

  variables {
    network_vlan_id = 1
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].vlan_id == 1
    error_message = "network_vlan_id = 1 must reach the network device's vlan_id."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 1
    error_message = "A VLAN tag must be applied to the existing network device, not to an additional one."
  }
}

run "the_highest_vlan_identifier_tags_the_existing_network_device" {
  command = plan

  variables {
    network_vlan_id = 4094
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].vlan_id == 4094
    error_message = "network_vlan_id = 4094 must reach the network device's vlan_id."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 1
    error_message = "A VLAN tag must be applied to the existing network device, not to an additional one."
  }
}

run "a_vlan_tag_leaves_the_network_and_connection_contracts_unchanged" {
  command = plan

  variables {
    network_vlan_id = 4094
  }

  # Without this, the run would pass just as well if the tag never arrived.
  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].vlan_id == 4094
    error_message = "The tag must be applied for this run to show that it leaves everything else unchanged."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].bridge == "vmbr0"
    error_message = "A VLAN tag must not change the declared bridge."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "A VLAN tag must not change the declared static IPv4 address or gateway."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].dns[0].servers == tolist(["192.0.2.53"])
    error_message = "A VLAN tag must not change the declared DNS servers."
  }

  assert {
    condition     = output.connection == { host = "192.0.2.10", user = "fictional", port = 22 }
    error_message = "A VLAN tag must not change the connection output."
  }
}
