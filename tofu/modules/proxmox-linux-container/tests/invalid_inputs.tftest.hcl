# Evidence that locally decidable invalid input fails early, before anything
# is planned against a provider.
#
# Each run supplies one invalid value and expects that variable's own
# validation to reject it. The provider is mocked and nothing is created.
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

run "invalid_hostname_is_rejected" {
  command = plan
  variables { name = "fictional container" }
  expect_failures = [var.name]
}

run "invalid_template_identifier_is_rejected" {
  command = plan
  variables { template_file_id = "debian-template" }
  expect_failures = [var.template_file_id]
}

run "zero_root_filesystem_size_is_rejected" {
  command = plan
  variables { root_filesystem_size_gb = 0 }
  expect_failures = [var.root_filesystem_size_gb]
}

run "fractional_cpu_count_is_rejected" {
  command = plan
  variables { cpu_cores = 1.5 }
  expect_failures = [var.cpu_cores]
}

run "zero_memory_is_rejected" {
  command = plan
  variables { memory_mib = 0 }
  expect_failures = [var.memory_mib]
}

run "invalid_bridge_is_rejected" {
  command = plan
  variables { network_bridge = "vmbr0 and another" }
  expect_failures = [var.network_bridge]
}

run "address_without_prefix_is_rejected" {
  command = plan
  variables { ipv4_address_cidr = "192.0.2.20" }
  expect_failures = [var.ipv4_address_cidr]
}

run "ipv6_address_is_rejected" {
  command = plan
  variables { ipv4_address_cidr = "2001:db8::20/64" }
  expect_failures = [var.ipv4_address_cidr]
}

run "gateway_with_prefix_is_rejected" {
  command = plan
  variables { ipv4_gateway = "192.0.2.1/24" }
  expect_failures = [var.ipv4_gateway]
}

run "empty_dns_list_is_rejected" {
  command = plan
  variables { dns_servers = [] }
  expect_failures = [var.dns_servers]
}

run "non_ipv4_dns_is_rejected" {
  command = plan
  variables { dns_servers = ["dns.example.invalid"] }
  expect_failures = [var.dns_servers]
}

run "empty_key_list_is_rejected" {
  command = plan
  variables { ssh_public_keys = [] }
  expect_failures = [var.ssh_public_keys]
}

run "non_key_value_is_rejected" {
  command = plan
  variables { ssh_public_keys = ["fictional-nonsense"] }
  expect_failures = [var.ssh_public_keys]
}

run "container_identifier_below_range_is_rejected" {
  command = plan
  variables { container_id = 42 }
  expect_failures = [var.container_id]
}

run "port_outside_tcp_range_is_rejected" {
  command = plan
  variables { ssh_port = 70000 }
  expect_failures = [var.ssh_port]
}

# A DNS name is dot-separated labels, each of letters, digits, and inner
# hyphens. The provider and Proxmox both reject the shapes below, so the module
# rejects them first, with its own message.
run "empty_hostname_is_rejected" {
  command = plan
  variables { name = "" }
  expect_failures = [var.name]
}

run "hostname_label_starting_with_a_hyphen_is_rejected" {
  command = plan
  variables { name = "fictional.-container.example.invalid" }
  expect_failures = [var.name]
}

run "hostname_label_ending_with_a_hyphen_is_rejected" {
  command = plan
  variables { name = "fictional-.example.invalid" }
  expect_failures = [var.name]
}

run "hostname_with_a_trailing_dot_is_rejected" {
  command = plan
  variables { name = "fictional-container.example.invalid." }
  expect_failures = [var.name]
}

run "hostname_with_an_empty_label_is_rejected" {
  command = plan
  variables { name = "fictional..example.invalid" }
  expect_failures = [var.name]
}

run "hostname_with_an_underscore_is_rejected" {
  command = plan
  variables { name = "fictional_container.example.invalid" }
  expect_failures = [var.name]
}

run "hostname_label_longer_than_63_characters_is_rejected" {
  command = plan
  variables { name = "a123456789012345678901234567890123456789012345678901234567890123.example.invalid" }
  expect_failures = [var.name]
}

run "hostname_longer_than_253_characters_is_rejected" {
  command = plan
  variables {
    name = join(".", [for index in range(26) : "fictional"], ["example.invalid"])
  }
  expect_failures = [var.name]
}

run "node_name_with_whitespace_is_rejected" {
  command = plan
  variables { node_name = "fictional node" }
  expect_failures = [var.node_name]
}

run "template_identifier_with_whitespace_is_rejected" {
  command = plan
  variables { template_file_id = "fictional-storage:vztmpl/debian 13.tar.zst" }
  expect_failures = [var.template_file_id]
}

run "datastore_identifier_with_whitespace_is_rejected" {
  command = plan
  variables { datastore_id = "fictional datastore" }
  expect_failures = [var.datastore_id]
}

run "fractional_root_filesystem_size_is_rejected" {
  command = plan
  variables { root_filesystem_size_gb = 16.5 }
  expect_failures = [var.root_filesystem_size_gb]
}

run "negative_root_filesystem_size_is_rejected" {
  command = plan
  variables { root_filesystem_size_gb = -16 }
  expect_failures = [var.root_filesystem_size_gb]
}

run "zero_cpu_count_is_rejected" {
  command = plan
  variables { cpu_cores = 0 }
  expect_failures = [var.cpu_cores]
}

run "fractional_memory_is_rejected" {
  command = plan
  variables { memory_mib = 2048.5 }
  expect_failures = [var.memory_mib]
}

run "address_given_as_dhcp_is_rejected" {
  command = plan
  variables { ipv4_address_cidr = "dhcp" }
  expect_failures = [var.ipv4_address_cidr]
}

run "gateway_that_is_not_an_ipv4_address_is_rejected" {
  command = plan
  variables { ipv4_gateway = "gateway.example.invalid" }
  expect_failures = [var.ipv4_gateway]
}

run "ipv6_dns_server_is_rejected" {
  command = plan
  variables { dns_servers = ["192.0.2.53", "2001:db8::53"] }
  expect_failures = [var.dns_servers]
}

run "one_non_key_among_valid_keys_is_rejected" {
  command = plan
  variables {
    ssh_public_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid",
      "fictional-nonsense",
    ]
  }
  expect_failures = [var.ssh_public_keys]
}

run "container_identifier_above_range_is_rejected" {
  command = plan
  variables { container_id = 1000000000 }
  expect_failures = [var.container_id]
}

run "fractional_container_identifier_is_rejected" {
  command = plan
  variables { container_id = 250.5 }
  expect_failures = [var.container_id]
}

run "port_zero_is_rejected" {
  command = plan
  variables { ssh_port = 0 }
  expect_failures = [var.ssh_port]
}

run "fractional_port_is_rejected" {
  command = plan
  variables { ssh_port = 22.5 }
  expect_failures = [var.ssh_port]
}

# Proxmox gives a container no less than 16 MiB, and the provider refuses
# fewer, so the module says so first.
run "memory_below_the_container_minimum_is_rejected" {
  command = plan
  variables { memory_mib = 15 }
  expect_failures = [var.memory_mib]
}

# The provider accepts at most 128 cores for a container.
run "cpu_count_above_the_provider_maximum_is_rejected" {
  command = plan
  variables { cpu_cores = 129 }
  expect_failures = [var.cpu_cores]
}

# cidrnetmask() accepts an IPv4-mapped IPv6 address and octets with leading
# zeros. Proxmox accepts neither, so the address rules do not rest on it.
run "ipv4_mapped_ipv6_address_is_rejected" {
  command = plan
  variables { ipv4_address_cidr = "::ffff:192.0.2.20/120" }
  expect_failures = [var.ipv4_address_cidr]
}

run "address_with_a_leading_zero_is_rejected" {
  command = plan
  variables { ipv4_address_cidr = "192.0.2.020/24" }
  expect_failures = [var.ipv4_address_cidr]
}

run "address_with_an_octet_above_255_is_rejected" {
  command = plan
  variables { ipv4_address_cidr = "192.0.2.256/24" }
  expect_failures = [var.ipv4_address_cidr]
}

run "address_with_a_prefix_above_32_is_rejected" {
  command = plan
  variables { ipv4_address_cidr = "192.0.2.20/33" }
  expect_failures = [var.ipv4_address_cidr]
}

run "gateway_with_a_leading_zero_is_rejected" {
  command = plan
  variables { ipv4_gateway = "192.0.2.01" }
  expect_failures = [var.ipv4_gateway]
}

run "ipv4_mapped_ipv6_gateway_is_rejected" {
  command = plan
  variables { ipv4_gateway = "::ffff:192.0.2.1" }
  expect_failures = [var.ipv4_gateway]
}

run "dns_server_with_a_leading_zero_is_rejected" {
  command = plan
  variables { dns_servers = ["192.0.2.053"] }
  expect_failures = [var.dns_servers]
}

# One entry is one key. A second line would reach Proxmox as it stands.
run "key_entry_spanning_two_lines_is_rejected" {
  command = plan
  variables {
    ssh_public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid\nfictional-nonsense"]
  }
  expect_failures = [var.ssh_public_keys]
}

run "key_with_more_padding_than_base64_allows_is_rejected" {
  command = plan
  variables { ssh_public_keys = ["ssh-ed25519 AAAA=== fictional@example.invalid"] }
  expect_failures = [var.ssh_public_keys]
}
