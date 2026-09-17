# Evidence that locally decidable invalid input fails early, before anything
# is planned against a provider.
#
# Each run supplies one invalid value and expects that variable's own
# validation to reject it. The provider is mocked and nothing is created.

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
