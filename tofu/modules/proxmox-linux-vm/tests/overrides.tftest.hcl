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

# These runs show additional attachments reaching the device and cloud-init
# lists at the declared positions. They do not show that Proxmox plugs or
# unplugs a device, that a guest configures an interface, or that the provider
# changes any of it in place: that is provider behaviour, which a mock cannot
# exercise. The MAC addresses come from the range RFC 7042 reserves for
# documentation.

run "additional_attachments_take_the_next_slots_in_declared_order" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr2" },
      { bridge = "vmbr1" },
    ]
  }

  # The declared order is deliberately not alphabetical, so a module that
  # sorted its attachments would fail here.
  assert {
    condition     = [for device in proxmox_virtual_environment_vm.this.network_device : device.bridge] == ["vmbr0", "vmbr2", "vmbr1"]
    error_message = "The primary attachment must be net0, followed by each additional attachment in the declared order."
  }
}

run "an_additional_attachment_maps_its_bridge_vlan_address_and_mac" {
  command = plan

  variables {
    additional_network_attachments = [
      {
        bridge            = "vmbr1"
        vlan_id           = 4094
        ipv4_address_cidr = "198.51.100.10/24"
        mac_address       = "00:00:5E:00:53:01"
      },
    ]
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[1].bridge == "vmbr1"
    error_message = "The additional attachment's bridge must reach net1."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[1].vlan_id == 4094
    error_message = "The additional attachment's VLAN must reach net1."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[1].mac_address == "00:00:5E:00:53:01"
    error_message = "The additional attachment's declared MAC address must reach net1 as given."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv4[0].address == "198.51.100.10/24"
    error_message = "The additional attachment's address must reach cloud-init IP configuration 1."
  }
}

run "an_additional_attachment_is_untagged_and_keeps_an_assigned_mac_unless_declared" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1" },
    ]
  }

  # The mock applies no provider defaults, so unset values plan as null here.
  # The real provider plans an unset tag as untagged, and an unset MAC address
  # as the one Proxmox assigns.
  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[1].vlan_id == null
    error_message = "An additional attachment without vlan_id must leave its device's tag unset."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[1].mac_address == null
    error_message = "An additional attachment without mac_address must leave its device's MAC address to Proxmox."
  }
}

run "only_the_primary_attachment_carries_a_gateway" {
  command = plan

  # gateway is not an attribute of an additional attachment. OpenTofu drops an
  # attribute the type does not declare, so this proves it goes nowhere.
  variables {
    additional_network_attachments = [
      {
        bridge            = "vmbr1"
        ipv4_address_cidr = "198.51.100.10/24"
        gateway           = "198.51.100.1"
      },
    ]
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "The primary attachment must keep its declared gateway."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv4[0].gateway == null
    error_message = "An additional attachment must never carry a gateway."
  }
}

run "an_addressless_attachment_after_the_last_addressed_slot_declares_no_ip_configuration" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", ipv4_address_cidr = "198.51.100.10/24" },
      { bridge = "vmbr2" },
    ]
  }

  # The provider reads back cloud-init IP configurations only up to the last
  # one Proxmox holds, so a trailing empty entry would never match its state.
  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 3
    error_message = "The addressless attachment must still be attached, at net2."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config) == 2
    error_message = "No cloud-init IP configuration may be declared after the last addressed slot."
  }
}

run "an_addressless_attachment_before_an_addressed_one_keeps_its_slot_empty" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1" },
      { bridge = "vmbr2", ipv4_address_cidr = "203.0.113.10/24" },
    ]
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config) == 3
    error_message = "The addressed attachment at net2 must keep IP configuration index 2."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv4) == 0 && length(proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv6) == 0
    error_message = "The addressless attachment's IP configuration entry must declare nothing."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[2].ipv4[0].address == "203.0.113.10/24"
    error_message = "The addressed attachment's address must reach IP configuration 2, not 1."
  }
}

run "eight_attachments_in_total_are_accepted" {
  command = plan

  variables {
    additional_network_attachments = [
      for slot in range(1, 8) : {
        bridge            = "vmbr${slot}"
        ipv4_address_cidr = "198.51.100.${slot}/24"
      }
    ]
  }

  assert {
    condition     = [for device in proxmox_virtual_environment_vm.this.network_device : device.bridge] == [for slot in range(8) : "vmbr${slot}"]
    error_message = "All eight attachments must be attached, each at its own slot."
  }

  assert {
    condition     = [for config in proxmox_virtual_environment_vm.this.initialization[0].ip_config : config.ipv4[0].address] == concat(["192.0.2.10/24"], [for slot in range(1, 8) : "198.51.100.${slot}/24"])
    error_message = "All eight attachments must reach cloud-init, each at its own IP configuration index."
  }
}

run "additional_attachments_leave_the_primary_and_connection_contracts_unchanged" {
  command = plan

  variables {
    network_vlan_id = 42
    additional_network_attachments = [
      { bridge = "vmbr1", vlan_id = 4094, ipv4_address_cidr = "198.51.100.10/24" },
    ]
  }

  # Without this, the run would pass just as well if the attachment never
  # arrived.
  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 2
    error_message = "The additional attachment must be attached for this run to show that it leaves the primary unchanged."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].bridge == "vmbr0" && proxmox_virtual_environment_vm.this.network_device[0].vlan_id == 42 && proxmox_virtual_environment_vm.this.network_device[0].mac_address == null
    error_message = "An additional attachment must not change the primary attachment's device."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "An additional attachment must not change the primary attachment's address or gateway."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].dns[0].servers == tolist(["192.0.2.53"])
    error_message = "An additional attachment must not change the declared DNS servers."
  }

  assert {
    condition     = output.connection == { host = "192.0.2.10", user = "fictional", port = 22 }
    error_message = "An additional attachment must not change the connection output."
  }
}

# The output needs applied values, so this run applies against the mock. It
# creates nothing. The mock does not assign MAC addresses the way Proxmox does,
# so an undeclared one is null here.
run "the_mac_output_reports_every_attachment_in_slot_order" {
  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", mac_address = "00:00:5E:00:53:02" },
      { bridge = "vmbr2" },
      { bridge = "vmbr3", mac_address = "00:00:5e:00:53:01" },
    ]
  }

  assert {
    condition     = output.mac_addresses == tolist([proxmox_virtual_environment_vm.this.network_device[0].mac_address, "00:00:5E:00:53:02", null, "00:00:5e:00:53:01"])
    error_message = "mac_addresses must list the primary and every additional attachment's MAC address, in slot order."
  }
}
