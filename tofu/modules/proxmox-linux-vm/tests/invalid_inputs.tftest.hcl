# Evidence that locally decidable invalid input fails early, before anything
# is planned against a provider.
#
# Each run supplies one invalid value and expects that variable's own
# validation to reject it, except the last, whose rule spans two variables and
# is the resource's precondition. The provider is mocked and nothing is created.

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

run "an_ipv6_address_in_the_ipv4_input_is_rejected" {
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

run "a_dns_server_that_is_not_an_ip_address_is_rejected" {
  command = plan

  variables {
    dns_servers = ["dns.example.invalid"]
  }

  expect_failures = [var.dns_servers]
}

run "a_dns_server_with_a_prefix_length_is_rejected" {
  command = plan

  variables {
    dns_servers = ["2001:db8::53/64"]
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

run "an_ipv6_address_without_a_prefix_length_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10"
  }

  expect_failures = [var.ipv6_address_cidr]
}

run "an_ipv4_address_in_the_ipv6_input_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "192.0.2.10/24"
  }

  expect_failures = [var.ipv6_address_cidr]
}

# An IPv4-mapped address is written like IPv6 but names an IPv4 address.
run "an_ipv4_mapped_address_in_the_ipv6_input_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "::ffff:192.0.2.10/120"
  }

  expect_failures = [var.ipv6_address_cidr]
}

run "an_ipv6_prefix_length_below_the_proxmox_range_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/7"
  }

  expect_failures = [var.ipv6_address_cidr]
}

run "an_ipv6_prefix_length_above_128_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/129"
  }

  expect_failures = [var.ipv6_address_cidr]
}

# Proxmox accepts these three non-address forms in the same field, and the
# pinned provider forwards them unchecked. Only static IPv6 is supported.
run "the_stateless_autoconfiguration_literal_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "auto"
  }

  expect_failures = [var.ipv6_address_cidr]
}

run "the_dhcpv6_literal_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "dhcp"
  }

  expect_failures = [var.ipv6_address_cidr]
}

run "the_manual_literal_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "manual"
  }

  expect_failures = [var.ipv6_address_cidr]
}

run "an_ipv6_gateway_carrying_a_prefix_length_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/64"
    ipv6_gateway      = "2001:db8::1/64"
  }

  expect_failures = [var.ipv6_gateway]
}

run "an_ipv4_address_in_the_ipv6_gateway_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/64"
    ipv6_gateway      = "192.0.2.1"
  }

  expect_failures = [var.ipv6_gateway]
}

# Proxmox's IPv6 format has no zone index, so a scoped link-local address is
# rejected rather than forwarded.
run "a_link_local_ipv6_gateway_with_a_zone_is_rejected" {
  command = plan

  variables {
    ipv6_address_cidr = "2001:db8::10/64"
    ipv6_gateway      = "fe80::1%eth0"
  }

  expect_failures = [var.ipv6_gateway]
}

# A gateway without an address is the one IPv6 rule that spans two variables,
# so the resource's precondition rejects it rather than either variable.
run "an_ipv6_gateway_without_an_ipv6_address_is_rejected" {
  command = plan

  variables {
    ipv6_gateway = "2001:db8::1"
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}
