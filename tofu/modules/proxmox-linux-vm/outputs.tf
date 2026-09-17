# Outputs are non-sensitive: the module publishes identity and the values a
# consumer needs to reach the guest, and never key material or a password.

output "connection" {
  description = "Where the bootstrap account can be reached: the declared IPv4 address without its prefix, the bootstrap username, and the ssh_port metadata value. It is a convenience for composing consumer-owned inventory, not a required integration: nothing in this toolkit consumes it at run time."

  value = {
    host = split("/", var.ipv4_address_cidr)[0]
    user = var.username
    port = var.ssh_port
  }
}

output "mac_addresses" {
  description = "MAC address of every network attachment, in slot order: the primary attachment's first, then each additional attachment's. A declared address is reported as given; the others are the ones Proxmox assigned."
  value       = proxmox_virtual_environment_vm.this.network_device[*].mac_address
}

output "vm_id" {
  description = "Identifier of the created VM, whether it was supplied or assigned by Proxmox."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "vm_name" {
  description = "Name of the created VM."
  value       = proxmox_virtual_environment_vm.this.name
}
