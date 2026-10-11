# Contract evidence for the default container behavior.
#
# The provider is mocked, so these runs need no Proxmox endpoint, credential,
# or network access and create nothing. They prove what the module asks the
# provider for and what it publishes as outputs. They prove nothing about a
# live Proxmox VE, a template, a container start, SSH, or a destroy.

# Every value below is fictional or reserved for documentation. The SSH key is
# a throwaway public key generated for these fixtures; nothing holds its
# private half.

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
  dns_servers             = ["192.0.2.53", "192.0.2.54"]
  ssh_public_keys         = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"]
}

run "container_identity_and_platform_are_explicit" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_container.this.node_name == "fictional-node"
    error_message = "The container must be created on the declared node."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.unprivileged == true
    error_message = "The first reusable container capability must always be unprivileged."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.start_on_boot == true
    error_message = "The module must explicitly start the container after a host boot."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.operating_system[0].template_file_id == "fictional-storage:vztmpl/debian-13-standard_13.0-1_amd64.tar.zst"
    error_message = "The declared template must reach the container resource."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.operating_system[0].type == "debian"
    error_message = "The operating-system type must be Debian rather than the provider's unmanaged default."
  }
}

run "resource_sizing_and_nesting_are_declared" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_container.this.cpu[0].cores == 2
    error_message = "The declared CPU core count must reach the resource."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.memory[0].dedicated == 2048
    error_message = "The declared dedicated memory must reach the resource."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.disk[0].datastore_id == "fictional-datastore" && proxmox_virtual_environment_container.this.disk[0].size == 16
    error_message = "The declared root filesystem datastore and size must reach the resource."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.features[0].nesting == true
    error_message = "Nesting must default to enabled."
  }
}

run "network_dns_and_key_only_bootstrap_are_declared" {
  command = plan

  assert {
    condition     = length(proxmox_virtual_environment_container.this.network_interface) == 1
    error_message = "The module must create exactly one network interface."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.network_interface[0].name == "veth0" && proxmox_virtual_environment_container.this.network_interface[0].bridge == "vmbr0"
    error_message = "The single interface must be veth0 on the declared bridge."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].hostname == "fictional-container.example.invalid"
    error_message = "The declared name must become the container hostname."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.20/24" && proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    error_message = "The declared static IPv4 address and gateway must reach initialization."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].dns[0].servers == tolist(["192.0.2.53", "192.0.2.54"])
    error_message = "Explicit DNS servers must reach initialization."
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.initialization[0].user_account[0].keys) == 1
    error_message = "The declared root SSH public keys must reach initialization."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].user_account[0].password == null
    error_message = "The module must not configure a root password."
  }
}

run "the_container_is_created_from_the_template_not_cloned" {
  command = plan

  assert {
    condition     = length(proxmox_virtual_environment_container.this.clone) == 0
    error_message = "The container must be created from the declared template, never cloned from another container."
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.operating_system) == 1
    error_message = "The module must declare exactly one operating-system block carrying the template."
  }
}

# The mock applies no provider defaults, so an argument the module leaves unset
# plans as null and a block it does not declare plans as an empty list. Each
# assertion below is therefore about what the module declares, which is the
# claim: the provider's own defaults for these are not this module's to prove.
run "nothing_outside_the_first_capability_is_declared" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_container.this.network_interface[0].vlan_id == null
    error_message = "The single interface must carry no VLAN tag."
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.initialization[0].ip_config) == 1 && length(proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv6) == 0
    error_message = "The module must declare one static IPv4 configuration and no IPv6 configuration."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address != "dhcp"
    error_message = "Addressing must be the declared static IPv4 CIDR rather than DHCP."
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.mount_point) == 0 && length(proxmox_virtual_environment_container.this.device_passthrough) == 0 && length(proxmox_virtual_environment_container.this.idmap) == 0
    error_message = "The module must declare no mount point, device passthrough, or ID mapping."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.features[0].keyctl == null && proxmox_virtual_environment_container.this.features[0].fuse == null && proxmox_virtual_environment_container.this.features[0].mknod == null && proxmox_virtual_environment_container.this.features[0].mount == null
    error_message = "Nesting is the only container feature the module may declare."
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.startup) == 0 && proxmox_virtual_environment_container.this.protection == null && proxmox_virtual_environment_container.this.pool_id == null
    error_message = "The module must declare no startup ordering, protection flag, or pool."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.timeout_create == null && proxmox_virtual_environment_container.this.timeout_update == null && proxmox_virtual_environment_container.this.timeout_delete == null
    error_message = "The module must expose no timeout or destroy-policy setting."
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.this.wait_for_ip) == 0
    error_message = "The module must not configure the provider's wait for a reported address."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.template == null && proxmox_virtual_environment_container.this.started == null
    error_message = "The module must not turn the container into a template or manage its power state."
  }
}

run "connection_output_is_declared_metadata" {
  command = plan

  assert {
    condition     = output.connection == { host = "192.0.2.20", user = "root", port = 22 }
    error_message = "The connection output must use the declared IPv4 host, root, and default port 22."
  }

  assert {
    condition     = output.container_name == "fictional-container.example.invalid"
    error_message = "The container_name output must preserve the declared hostname."
  }
}

# The provider reports the addresses a started container holds and the
# identifier Proxmox assigned. The override makes it report an address the
# consumer never declared and an identifier nobody supplied, on an apply the
# mock performs. The published host must still be the declared address, and
# the published identifier must be the container's own.
run "outputs_after_creation_use_the_declared_host_and_the_assigned_identifier" {
  command = apply

  override_resource {
    target = proxmox_virtual_environment_container.this
    values = {
      vm_id = 250
      ipv4 = {
        veth0 = "198.51.100.99"
      }
    }
  }

  assert {
    condition     = output.container_id == 250
    error_message = "With no container_id supplied, the container_id output must publish the identifier the container was given."
  }

  assert {
    condition     = proxmox_virtual_environment_container.this.ipv4["veth0"] == "198.51.100.99"
    error_message = "The fixture must make the provider report an address other than the declared one."
  }

  assert {
    condition     = output.connection.host == "192.0.2.20"
    error_message = "connection.host must stay the declared address whatever the provider reports."
  }
}
