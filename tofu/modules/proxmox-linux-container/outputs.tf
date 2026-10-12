# Outputs are non-sensitive and do not depend on provider-reported addressing.

output "connection" {
  description = "Where root can be reached after consumer-owned networking and SSH are working."
  value = {
    host = split("/", var.ipv4_address_cidr)[0]
    user = "root"
    port = var.ssh_port
  }
}

output "container_id" {
  description = "Identifier of the created container, whether supplied or assigned by Proxmox."
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "container_name" {
  description = "Declared container hostname."
  value       = var.name
}
