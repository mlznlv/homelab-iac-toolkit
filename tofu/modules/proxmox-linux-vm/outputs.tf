# Outputs are non-sensitive: the module publishes identity and the values a
# consumer needs to reach the guest, and never key material or a password.

output "connection" {
  description = "Where the bootstrap account can be reached: connection_host when it is supplied, and otherwise the declared static IPv4 address without its prefix; the bootstrap username; and the ssh_port metadata value. Every value is declared, never discovered. It is a convenience for composing consumer-owned inventory, not a required integration: nothing in this toolkit consumes it at run time."

  # Never derived from a lease, an agent-reported or provider-read address, or
  # state. A configuration that would reach the null branch below fails the
  # resource's preconditions, so a null host is never published.
  value = {
    host = var.connection_host != null ? var.connection_host : (var.ipv4_address_cidr != null ? split("/", var.ipv4_address_cidr)[0] : null)
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
