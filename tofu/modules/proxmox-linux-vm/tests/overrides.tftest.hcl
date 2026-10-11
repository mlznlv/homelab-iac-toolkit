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

# These runs show the addressing mode, the connection host, and the primary MAC
# address reaching the resource and the connection output. They do not show
# that Proxmox applies them, that the provider changes an existing VM in place,
# that a DHCP service grants a lease, or that a connection host reaches the
# guest: that is provider and runtime behaviour, which a mock cannot exercise.

run "dhcp_declares_dhcp_on_the_primary_ip_configuration" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
    connection_host   = "fictional-vm.example.invalid"
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config) == 1
    error_message = "DHCP must be declared on the primary IP configuration, not on an additional one."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "dhcp"
    error_message = "With ipv4_mode = \"dhcp\", the primary IP configuration must request DHCP explicitly."
  }

  # The mock applies no provider defaults, so the absent gateway plans as null
  # here. The real provider plans it as an empty string, which it does not send.
  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == null
    error_message = "With ipv4_mode = \"dhcp\", the primary IP configuration must declare no gateway."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].dns[0].servers == tolist(["192.0.2.53"])
    error_message = "DHCP must still give the guest the declared DNS servers."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 1 && proxmox_virtual_environment_vm.this.network_device[0].bridge == "vmbr0"
    error_message = "DHCP must leave the primary network device as it is."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.agent[0].wait_for_ip[0].disabled == true
    error_message = "DHCP must not turn on waiting for an agent-reported address."
  }
}

run "dhcp_publishes_the_supplied_connection_host" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
    connection_host   = "fictional-vm.example.invalid"
  }

  assert {
    condition     = output.connection == { host = "fictional-vm.example.invalid", user = "fictional", port = 22 }
    error_message = "With ipv4_mode = \"dhcp\", connection must publish the supplied connection_host with the unchanged user and port."
  }
}

run "dhcp_accepts_an_ipv4_connection_host" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
    connection_host   = "192.0.2.20"
  }

  assert {
    condition     = output.connection.host == "192.0.2.20"
    error_message = "An IPv4 address literal must be accepted and published as connection.host."
  }
}

run "dhcp_accepts_an_ipv6_connection_host" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
    connection_host   = "2001:db8::20"
  }

  assert {
    condition     = output.connection.host == "2001:db8::20"
    error_message = "An IPv6 address literal must be accepted and published as connection.host."
  }
}

run "static_publishes_a_supplied_connection_host_instead_of_the_address" {
  command = plan

  variables {
    connection_host = "fictional-vm.example.invalid"
  }

  assert {
    condition     = output.connection == { host = "fictional-vm.example.invalid", user = "fictional", port = 22 }
    error_message = "In static mode, a supplied connection_host must replace the declared address in connection.host."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "A connection_host is metadata only, and must not change the declared static address or gateway."
  }
}

run "a_null_ipv4_mode_is_the_static_default" {
  command = plan

  variables {
    ipv4_mode = null
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "A null ipv4_mode must behave as the static default."
  }
}

run "a_primary_mac_address_reaches_the_primary_network_device" {
  command = plan

  variables {
    network_mac_address = "00:00:5E:00:53:01"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].mac_address == "00:00:5E:00:53:01"
    error_message = "network_mac_address must reach the primary network device."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 1 && proxmox_virtual_environment_vm.this.network_device[0].bridge == "vmbr0"
    error_message = "A primary MAC address must be set on the existing network device, not on an additional one."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24" && output.connection == { host = "192.0.2.10", user = "fictional", port = 22 }
    error_message = "A primary MAC address must not change the addressing or the connection output."
  }
}

run "a_primary_mac_address_is_passed_through_as_given" {
  command = plan

  variables {
    network_mac_address = "00:00:5e:00:53:0a"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].mac_address == "00:00:5e:00:53:0a"
    error_message = "A lowercase MAC address must be accepted and reach the device as written."
  }
}

run "a_primary_mac_address_reaches_the_primary_network_device_in_dhcp_mode" {
  command = plan

  variables {
    ipv4_mode           = "dhcp"
    ipv4_address_cidr   = null
    ipv4_gateway        = null
    connection_host     = "fictional-vm.example.invalid"
    network_mac_address = "00:00:5E:00:53:01"
    network_vlan_id     = 42
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].mac_address == "00:00:5E:00:53:01"
    error_message = "network_mac_address must reach the primary network device in DHCP mode too."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].vlan_id == 42
    error_message = "A primary MAC address must leave the VLAN tag as declared."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "dhcp"
    error_message = "A primary MAC address must leave the DHCP mode as declared."
  }
}
