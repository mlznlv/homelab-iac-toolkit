# Evidence that locally decidable invalid input fails early, before anything
# is planned against a provider.
#
# Each run supplies one invalid value and expects the rule that owns it to
# reject it: that variable's own validation, or, where a rule spans the primary
# and the additional attachments, the resource's precondition. The provider is
# mocked and nothing is created.

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

run "an_address_without_a_prefix_length_is_rejected" {
  command = plan

  variables {
    ipv4_address_cidr = "192.0.2.10"
  }

  expect_failures = [var.ipv4_address_cidr]
}

run "an_ipv6_address_is_rejected" {
  command = plan

  variables {
    ipv4_address_cidr = "2001:db8::10/64"
  }

  expect_failures = [var.ipv4_address_cidr]
}

run "a_gateway_carrying_a_prefix_length_is_rejected" {
  command = plan

  variables {
    ipv4_gateway = "192.0.2.1/24"
  }

  expect_failures = [var.ipv4_gateway]
}

run "an_empty_dns_server_list_is_rejected" {
  command = plan

  variables {
    dns_servers = []
  }

  expect_failures = [var.dns_servers]
}

run "a_dns_server_that_is_not_an_ipv4_address_is_rejected" {
  command = plan

  variables {
    dns_servers = ["dns.example.invalid"]
  }

  expect_failures = [var.dns_servers]
}

run "an_empty_ssh_public_key_list_is_rejected" {
  command = plan

  variables {
    ssh_public_keys = []
  }

  expect_failures = [var.ssh_public_keys]
}

run "a_value_that_is_not_an_openssh_public_key_is_rejected" {
  command = plan

  variables {
    ssh_public_keys = ["fictional-nonsense"]
  }

  expect_failures = [var.ssh_public_keys]
}

run "a_username_that_is_not_a_valid_account_name_is_rejected" {
  command = plan

  variables {
    username = "Fictional User"
  }

  expect_failures = [var.username]
}

run "a_vm_name_that_is_not_a_dns_label_is_rejected" {
  command = plan

  variables {
    name = "fictional_vm"
  }

  expect_failures = [var.name]
}

run "a_template_identifier_below_the_proxmox_range_is_rejected" {
  command = plan

  variables {
    template_id = 42
  }

  expect_failures = [var.template_id]
}

run "a_vm_identifier_below_the_proxmox_range_is_rejected" {
  command = plan

  variables {
    vm_id = 42
  }

  expect_failures = [var.vm_id]
}

run "a_fractional_cpu_core_count_is_rejected" {
  command = plan

  variables {
    cpu_cores = 1.5
  }

  expect_failures = [var.cpu_cores]
}

run "a_memory_size_of_zero_is_rejected" {
  command = plan

  variables {
    memory_mib = 0
  }

  expect_failures = [var.memory_mib]
}

run "a_connection_port_outside_the_tcp_range_is_rejected" {
  command = plan

  variables {
    ssh_port = 70000
  }

  expect_failures = [var.ssh_port]
}

run "a_bridge_name_that_is_not_an_interface_name_is_rejected" {
  command = plan

  variables {
    network_bridge = "vmbr0 and another"
  }

  expect_failures = [var.network_bridge]
}

# The provider spells an untagged device as tag 0. The module's only way to say
# untagged is null, so 0 is rejected rather than accepted as a second spelling.
run "a_vlan_identifier_of_zero_is_rejected" {
  command = plan

  variables {
    network_vlan_id = 0
  }

  expect_failures = [var.network_vlan_id]
}

run "a_negative_vlan_identifier_is_rejected" {
  command = plan

  variables {
    network_vlan_id = -1
  }

  expect_failures = [var.network_vlan_id]
}

run "a_fractional_vlan_identifier_is_rejected" {
  command = plan

  variables {
    network_vlan_id = 1.5
  }

  expect_failures = [var.network_vlan_id]
}

run "a_vlan_identifier_above_the_vlan_range_is_rejected" {
  command = plan

  variables {
    network_vlan_id = 4095
  }

  expect_failures = [var.network_vlan_id]
}

# Additional attachments. The MAC addresses come from the ranges RFC 7042
# reserves for documentation.

run "more_than_eight_attachments_in_total_are_rejected" {
  command = plan

  variables {
    additional_network_attachments = [for slot in range(1, 9) : { bridge = "vmbr${slot}" }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_attachment_that_is_null_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [null]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_attachment_without_a_bridge_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = null }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_bridge_that_is_not_an_interface_name_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1 and another" }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_vlan_identifier_of_zero_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", vlan_id = 0 }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "a_fractional_additional_vlan_identifier_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", vlan_id = 1.5 }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_vlan_identifier_above_the_vlan_range_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", vlan_id = 4095 }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_address_without_a_prefix_length_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", ipv4_address_cidr = "198.51.100.10" }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_ipv6_address_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", ipv4_address_cidr = "2001:db8::10/64" }]
  }

  expect_failures = [var.additional_network_attachments]
}

# cidrnetmask() accepts an IPv4-mapped IPv6 address, so the rule does not rest
# on it.
run "an_additional_ipv4_mapped_ipv6_address_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", ipv4_address_cidr = "::ffff:198.51.100.10/120" }]
  }

  expect_failures = [var.additional_network_attachments]
}

# Proxmox refuses an octet written with a leading zero, so the module does too.
run "an_additional_address_with_a_leading_zero_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", ipv4_address_cidr = "198.51.100.010/24" }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_address_with_an_octet_above_255_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", ipv4_address_cidr = "198.51.100.256/24" }]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_additional_address_with_a_prefix_above_32_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", ipv4_address_cidr = "198.51.100.10/33" }]
  }

  expect_failures = [var.additional_network_attachments]
}

# Proxmox accepts a prefix length from 8 to 32.
run "an_additional_address_with_a_prefix_below_8_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", ipv4_address_cidr = "198.51.100.10/7" }]
  }

  expect_failures = [var.additional_network_attachments]
}

# Duplicates are compared by address, whatever prefix length each carries.
run "two_additional_attachments_with_the_same_address_are_rejected" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", ipv4_address_cidr = "198.51.100.10/24" },
      { bridge = "vmbr2", ipv4_address_cidr = "198.51.100.10/25" },
    ]
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "an_additional_attachment_with_the_primary_address_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", ipv4_address_cidr = "192.0.2.10/24" }]
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "a_malformed_mac_address_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", mac_address = "00-00-5E-00-53-01" }]
  }

  expect_failures = [var.additional_network_attachments]
}

# Proxmox refuses a MAC address with the group bit set, so the module does too.
run "a_multicast_mac_address_is_rejected" {
  command = plan

  variables {
    additional_network_attachments = [{ bridge = "vmbr1", mac_address = "01:00:5E:90:10:01" }]
  }

  expect_failures = [var.additional_network_attachments]
}

# Two attachments declaring one MAC address would give the guest two devices it
# cannot tell apart, so the module refuses it before Proxmox is asked.
run "two_additional_attachments_declaring_the_same_mac_address_are_rejected" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", mac_address = "00:00:5E:00:53:01" },
      { bridge = "vmbr2", mac_address = "00:00:5E:00:53:01" },
    ]
  }

  expect_failures = [var.additional_network_attachments]
}

# Letter case is not part of a MAC address, so it cannot make two declarations
# of one address differ.
run "duplicate_mac_addresses_are_compared_without_regard_to_letter_case" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", mac_address = "00:00:5E:00:53:0A" },
      { bridge = "vmbr2", mac_address = "00:00:5e:00:53:0a" },
    ]
  }

  expect_failures = [var.additional_network_attachments]
}

# The duplicates need not be neighbours, and an attachment that declares no MAC
# address between them changes nothing.
run "a_duplicate_mac_address_is_rejected_wherever_it_appears_in_the_list" {
  command = plan

  variables {
    additional_network_attachments = [
      { bridge = "vmbr1", mac_address = "00:00:5E:00:53:01" },
      { bridge = "vmbr2" },
      { bridge = "vmbr3", mac_address = "00:00:5E:00:53:02" },
      { bridge = "vmbr4", mac_address = "00:00:5e:00:53:01" },
    ]
  }

  expect_failures = [var.additional_network_attachments]
}

run "an_unknown_ipv4_mode_is_rejected" {
  command = plan

  variables {
    ipv4_mode = "manual"
  }

  expect_failures = [var.ipv4_mode]
}

run "an_ipv4_mode_written_in_another_case_is_rejected" {
  command = plan

  variables {
    ipv4_mode = "DHCP"
  }

  expect_failures = [var.ipv4_mode]
}

# DHCP is selected by the mode, never by smuggling Proxmox's literal into the
# static address.
run "dhcp_cannot_be_requested_through_the_static_address" {
  command = plan

  variables {
    ipv4_address_cidr = "dhcp"
  }

  expect_failures = [var.ipv4_address_cidr]
}

# The rules below span more than one input, so they are the resource's
# preconditions rather than a variable's validation. Each run breaks exactly
# one of them.

run "static_mode_without_an_address_is_rejected" {
  command = plan

  variables {
    ipv4_address_cidr = null
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "static_mode_without_a_gateway_is_rejected" {
  command = plan

  variables {
    ipv4_gateway = null
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "dhcp_with_a_declared_address_is_rejected" {
  command = plan

  variables {
    ipv4_mode       = "dhcp"
    ipv4_gateway    = null
    connection_host = "fictional-vm.example.invalid"
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "dhcp_with_a_declared_gateway_is_rejected" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    connection_host   = "fictional-vm.example.invalid"
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "dhcp_without_a_connection_host_is_rejected" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "dhcp_without_dns_servers_is_rejected" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
    connection_host   = "fictional-vm.example.invalid"
    dns_servers       = []
  }

  expect_failures = [var.dns_servers]
}

run "a_connection_host_with_a_scheme_is_rejected" {
  command = plan

  variables {
    connection_host = "ssh://fictional-vm.example.invalid"
  }

  expect_failures = [var.connection_host]
}

run "a_connection_host_with_a_port_is_rejected" {
  command = plan

  variables {
    connection_host = "fictional-vm.example.invalid:22"
  }

  expect_failures = [var.connection_host]
}

run "a_bracketed_ipv6_connection_host_is_rejected" {
  command = plan

  variables {
    connection_host = "[2001:db8::20]"
  }

  expect_failures = [var.connection_host]
}

run "a_connection_host_with_a_prefix_length_is_rejected" {
  command = plan

  variables {
    connection_host = "192.0.2.20/24"
  }

  expect_failures = [var.connection_host]
}

run "a_connection_host_that_is_a_mistyped_ipv4_address_is_rejected" {
  command = plan

  variables {
    connection_host = "192.0.2.300"
  }

  expect_failures = [var.connection_host]
}

run "a_connection_host_containing_whitespace_is_rejected" {
  command = plan

  variables {
    connection_host = "fictional vm"
  }

  expect_failures = [var.connection_host]
}

run "an_empty_connection_host_is_rejected" {
  command = plan

  variables {
    connection_host = ""
  }

  expect_failures = [var.connection_host]
}

run "a_malformed_connection_host_is_rejected_in_dhcp_mode" {
  command = plan

  variables {
    ipv4_mode         = "dhcp"
    ipv4_address_cidr = null
    ipv4_gateway      = null
    connection_host   = "fictional_vm.example.invalid"
  }

  expect_failures = [var.connection_host]
}

# Proxmox refuses a MAC address with the group bit set, which marks a
# multicast address.
run "a_multicast_primary_mac_address_is_rejected" {
  command = plan

  variables {
    network_mac_address = "01:00:5E:00:53:01"
  }

  expect_failures = [var.network_mac_address]
}

run "a_primary_mac_address_with_other_separators_is_rejected" {
  command = plan

  variables {
    network_mac_address = "00-00-5E-00-53-01"
  }

  expect_failures = [var.network_mac_address]
}

run "a_primary_mac_address_with_too_few_octets_is_rejected" {
  command = plan

  variables {
    network_mac_address = "00:00:5E:00:53"
  }

  expect_failures = [var.network_mac_address]
}

run "a_primary_mac_address_that_is_not_hexadecimal_is_rejected" {
  command = plan

  variables {
    network_mac_address = "00:00:5E:00:53:ZZ"
  }

  expect_failures = [var.network_mac_address]
}
