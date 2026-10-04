# Evidence that locally decidable invalid input fails before apply.

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
