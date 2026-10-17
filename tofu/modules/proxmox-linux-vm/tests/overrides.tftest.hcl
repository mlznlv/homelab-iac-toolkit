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

# The primary address, gateway, and DNS server rules are written out rather
# than delegated, so their limits are pinned: an octet of 0 or 255 and both
# ends of the prefix range are accepted. The values just past them are
# rejected in invalid_inputs.tftest.hcl.
run "the_primary_ipv4_inputs_may_use_an_octet_of_255_and_a_prefix_length_of_32" {
  command = plan

  variables {
    ipv4_address_cidr = "192.0.2.255/32"
    ipv4_gateway      = "198.51.100.255"
    dns_servers       = ["203.0.113.255"]
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.255/32" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "198.51.100.255"
    error_message = "An octet of 255 and a prefix length of 32 must be accepted and reach the primary IP configuration as given."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].dns[0].servers == tolist(["203.0.113.255"])
    error_message = "A DNS server with an octet of 255 must be accepted and reach cloud-init as given."
  }
}

run "the_primary_ipv4_inputs_may_use_an_octet_of_0_and_a_prefix_length_of_8" {
  command = plan

  variables {
    ipv4_address_cidr = "192.0.2.0/8"
    ipv4_gateway      = "198.51.100.0"
    dns_servers       = ["203.0.113.0"]
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.0/8" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "198.51.100.0"
    error_message = "An octet of 0 and a prefix length of 8 must be accepted and reach the primary IP configuration as given."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].dns[0].servers == tolist(["203.0.113.0"])
    error_message = "A DNS server with an octet of 0 must be accepted and reach cloud-init as given."
  }
}

# The key rule allows one key per entry on one line, with or without a
# comment, and ignores the surrounding whitespace a key read from a file
# carries. Only acceptance is pinned here, so each entry is compared without
# that whitespace. The ECDSA key is a second throwaway public key, chosen
# because its encoding ends in the two padding characters base64 allows;
# nothing holds its private half either.
run "accepted_key_forms_reach_the_bootstrap_account" {
  command = plan

  variables {
    ssh_public_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 Fictional User on fictional-workstation",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid\n",
      "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBLiiaVaauBuzwEZC9gOScy6wYIsRnIW9wHcKxI4dFAvcYFQw+R/WHzhAKFsPlNZ9qpcXgn7Ix6bY5NtdmLFGSODgqQQ71iMl6tWjndxJpVb0lvXgtqKtYIKsEdXwcX3OzA== fictional@example.invalid",
    ]
  }

  assert {
    condition = [for key in proxmox_virtual_environment_vm.this.initialization[0].user_account[0].keys : trimspace(key)] == [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 Fictional User on fictional-workstation",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid",
      "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBLiiaVaauBuzwEZC9gOScy6wYIsRnIW9wHcKxI4dFAvcYFQw+R/WHzhAKFsPlNZ9qpcXgn7Ix6bY5NtdmLFGSODgqQQ71iMl6tWjndxJpVb0lvXgtqKtYIKsEdXwcX3OzA== fictional@example.invalid",
    ]
    error_message = "A key without a comment, a comment containing spaces, a trailing newline, and two padding characters must all be accepted, and every entry must reach the bootstrap account in the declared order."
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

  # Written out rather than built with range(), because OpenTofu 1.9.4 does
  # not allow a function call in a run's variables.
  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", ipv4_address_cidr = "198.51.100.1/24" },
      { bridge = "vmbr2", ipv4_address_cidr = "198.51.100.2/24" },
      { bridge = "vmbr3", ipv4_address_cidr = "198.51.100.3/24" },
      { bridge = "vmbr4", ipv4_address_cidr = "198.51.100.4/24" },
      { bridge = "vmbr5", ipv4_address_cidr = "198.51.100.5/24" },
      { bridge = "vmbr6", ipv4_address_cidr = "198.51.100.6/24" },
      { bridge = "vmbr7", ipv4_address_cidr = "198.51.100.7/24" },
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

# The address rule is written out rather than delegated, so its limits are
# pinned: the highest octet and both ends of the prefix range are accepted.
run "an_additional_address_may_use_the_octet_and_prefix_limits" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", ipv4_address_cidr = "203.0.113.255/32" },
      { bridge = "vmbr2", ipv4_address_cidr = "198.51.100.0/8" },
    ]
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv4[0].address == "203.0.113.255/32"
    error_message = "An octet of 255 and a prefix length of 32 must be accepted and reach cloud-init IP configuration 1 as given."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[2].ipv4[0].address == "198.51.100.0/8"
    error_message = "An octet of 0 and a prefix length of 8 must be accepted and reach cloud-init IP configuration 2 as given."
  }
}

# Uniqueness is a rule about declared MAC addresses only. Attachments that
# leave the choice to Proxmox are not duplicates of one another, and declared
# addresses that differ in any octet are accepted.
run "undeclared_and_distinct_mac_addresses_are_accepted_together" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1" },
      { bridge = "vmbr2", mac_address = "00:00:5E:00:53:01" },
      { bridge = "vmbr3" },
      { bridge = "vmbr4", mac_address = "00:00:5E:00:53:02" },
    ]
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 5
    error_message = "Two undeclared and two distinct declared MAC addresses must all be accepted."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[1].mac_address == null && proxmox_virtual_environment_vm.this.network_device[3].mac_address == null
    error_message = "An attachment that declares no MAC address must leave its device's MAC address to Proxmox."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[2].mac_address == "00:00:5E:00:53:01" && proxmox_virtual_environment_vm.this.network_device[4].mac_address == "00:00:5E:00:53:02"
    error_message = "Each declared MAC address must reach its own slot as given."
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

# These runs show the primary attachment's DHCP mode and MAC address alongside
# additional attachments, which stay static or addressless whatever the
# primary does.

run "dhcp_on_the_primary_leaves_additional_attachments_static" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
    connection_host   = "fictional-vm.example.invalid"
    additional_network_attachments = [
      { bridge = "vmbr1", ipv4_address_cidr = "198.51.100.10/24" },
    ]
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config) == 2
    error_message = "A DHCP primary and one addressed additional attachment must declare exactly two IP configurations."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "dhcp" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == null
    error_message = "The primary IP configuration must request DHCP, with no gateway."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv4[0].address == "198.51.100.10/24" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv4[0].gateway == null
    error_message = "An additional attachment must keep its declared static address, with no gateway, when the primary uses DHCP."
  }

  assert {
    condition     = output.connection == { host = "fictional-vm.example.invalid", user = "fictional", port = 22 }
    error_message = "connection must stay primary-only: additional attachments never supply its host."
  }
}

# ipv4_mode is not an attribute of an additional attachment. OpenTofu drops an
# attribute the type does not declare, so this proves it goes nowhere.
run "an_ipv4_mode_on_an_additional_attachment_goes_nowhere" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", ipv4_mode = "dhcp" },
    ]
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 2
    error_message = "The additional attachment must still be attached."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config) == 1 && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24"
    error_message = "An ipv4_mode on an additional attachment must declare no IP configuration for it and leave the primary static."
  }
}

# The output needs applied values, so this run applies against the mock. It
# creates nothing.
run "the_mac_output_reports_a_declared_primary_mac_address_first" {
  variables {
    network_mac_address = "00:00:5E:00:53:01"
    additional_network_attachments = [
      { bridge = "vmbr1", mac_address = "00:00:5E:00:53:02" },
    ]
  }

  assert {
    condition     = output.mac_addresses == tolist(["00:00:5E:00:53:01", "00:00:5E:00:53:02"])
    error_message = "mac_addresses must report the declared primary MAC address first, then each additional attachment's."
  }
}

# These runs show static IPv6 reaching the primary IP configuration beside its
# static or DHCP IPv4 one. They do not show that Proxmox or a guest applies it, or that
# the provider changes it in place: that is provider behaviour, which a mock
# cannot exercise.

run "a_static_ipv6_address_is_added_beside_the_ipv4_configuration" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/64"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].address == "2001:db8::10/64"
    error_message = "ipv6_address_cidr must reach the IPv6 address of the existing IP configuration."
  }

  # The mock applies no provider defaults, so an unset gateway plans as null
  # here. The real provider plans it as its empty default and sends nothing.
  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].gateway == null
    error_message = "With no ipv6_gateway, the IPv6 gateway must be left unset."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "IPv6 must be added beside the declared static IPv4 address and gateway, not in place of them."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config) == 1 && length(proxmox_virtual_environment_vm.this.network_device) == 1
    error_message = "IPv6 must be added to the existing IP configuration, without another IP configuration or network device."
  }
}


run "a_global_ipv6_gateway_reaches_the_ip_configuration" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/64"
    ipv6_gateway      = "2001:db8::1"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].address == "2001:db8::10/64" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].gateway == "2001:db8::1"
    error_message = "ipv6_gateway must reach the IPv6 gateway beside the declared IPv6 address."
  }
}


run "a_link_local_ipv6_gateway_reaches_the_ip_configuration" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/64"
    ipv6_gateway      = "fe80::1"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].gateway == "fe80::1"
    error_message = "A link-local ipv6_gateway must be accepted and reach the IPv6 gateway."
  }
}


run "the_longest_ipv6_prefix_length_is_accepted" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/128"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].address == "2001:db8::10/128"
    error_message = "A /128 IPv6 address, the longest prefix, must be accepted."
  }
}


run "the_shortest_ipv6_prefix_length_is_accepted" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/8"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].address == "2001:db8::10/8"
    error_message = "A /8 IPv6 address, the shortest prefix Proxmox accepts, must be accepted."
  }
}


run "ipv6_never_becomes_the_connection_host" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/64"
    ipv6_gateway      = "2001:db8::1"
  }

  # Without this, the run would pass just as well if IPv6 never arrived.
  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].address == "2001:db8::10/64"
    error_message = "IPv6 must be declared for this run to show that it leaves the connection output unchanged."
  }

  assert {
    condition     = output.connection == { host = "192.0.2.10", user = "fictional", port = 22 }
    error_message = "A declared IPv6 address must not change the connection output: host stays the declared IPv4 address."
  }
}


run "a_static_ipv6_address_is_added_beside_dhcp_ipv4" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
    connection_host   = "fictional-vm.example.invalid"
    ipv6_address_cidr = "2001:db8::10/64"
    ipv6_gateway      = "2001:db8::1"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].address == "2001:db8::10/64" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].gateway == "2001:db8::1"
    error_message = "ipv6_address_cidr and ipv6_gateway must reach the primary IP configuration in DHCP mode too."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "dhcp" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == null
    error_message = "IPv6 must be added beside the DHCP IPv4 configuration, not in place of it."
  }

  assert {
    condition     = output.connection == { host = "fictional-vm.example.invalid", user = "fictional", port = 22 }
    error_message = "In DHCP mode, connection must publish the supplied connection_host, never the declared IPv6 address."
  }
}

# Choosing an IPv6 host is the consumer's, through connection_host; the module
# never makes that choice from ipv6_address_cidr.
run "a_supplied_ipv6_connection_host_is_published_beside_declared_ipv6" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/64"
    connection_host   = "2001:db8::10"
  }

  assert {
    condition     = output.connection == { host = "2001:db8::10", user = "fictional", port = 22 }
    error_message = "A supplied IPv6 connection_host must be published as connection.host."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].address == "2001:db8::10/64"
    error_message = "A connection_host is metadata only, and must not change the declared IPv4 or IPv6 addressing."
  }
}

run "ipv6_dns_servers_are_accepted_beside_ipv4_ones" {
  command = plan

  variables {
    dns_servers = ["2001:db8::53", "192.0.2.53"]
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].dns[0].servers == tolist(["2001:db8::53", "192.0.2.53"])
    error_message = "IPv6 and IPv4 DNS servers must both reach cloud-init in the declared order."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6) == 0
    error_message = "An IPv6 DNS server must not declare IPv6 addressing."
  }
}


run "ipv6_stays_on_the_primary_attachment" {
  command = plan

  # IPv6 is not an attribute of an additional attachment. OpenTofu drops an
  # attribute the type does not declare, so this proves it goes nowhere.
  variables {
    ipv6_address_cidr = "2001:db8::10/64"
    ipv6_gateway      = "2001:db8::1"

    additional_network_attachments = [
      {
        bridge            = "vmbr1"
        ipv4_address_cidr = "198.51.100.10/24"
        ipv6_address_cidr = "2001:db8:1::10/64"
        ipv6_gateway      = "2001:db8:1::1"
      },
    ]
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6) == 1 && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].address == "2001:db8::10/64" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv6[0].gateway == "2001:db8::1"
    error_message = "The primary attachment must carry exactly the declared IPv6 address and gateway."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv6) == 0
    error_message = "An additional attachment must never carry IPv6."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv4[0].address == "198.51.100.10/24" && proxmox_virtual_environment_vm.this.initialization[0].ip_config[1].ipv4[0].gateway == null
    error_message = "Primary IPv6 must leave an additional attachment's IPv4 configuration as declared."
  }
}
