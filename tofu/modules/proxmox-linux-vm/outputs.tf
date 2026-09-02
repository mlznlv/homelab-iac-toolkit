# Outputs are non-sensitive: the module publishes identity and the values a
# consumer needs to reach the guest, and never key material or a password.

output "connection" {
  description = "Where the bootstrap account can be reached: the declared IPv4 address without its prefix, the bootstrap username, and the ssh_port metadata value. It is a convenience for composing consumer-owned inventory, not a required integration: nothing in this toolkit consumes it."

  value = {
    host = split("/", var.ipv4_address_cidr)[0]
    user = var.username
    port = var.ssh_port
  }
}

output "vm_id" {
  description = "Identifier of the created VM, whether it was supplied or assigned by Proxmox."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "vm_name" {
  description = "Name of the created VM."
  value       = proxmox_virtual_environment_vm.this.name
}
