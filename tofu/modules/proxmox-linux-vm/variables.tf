# Inputs are consumer-owned. The module supplies no default endpoint, node,
# template, datastore, address, or key: every value that describes an
# environment is passed in, and the defaults that do exist are behavioural.

variable "name" {
  description = "Name of the VM to create. Proxmox requires a valid DNS name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$", var.name))
    error_message = "The name must be a DNS label: letters, digits, and inner hyphens, at most 63 characters."
  }
}

variable "node_name" {
  description = "Name of the Proxmox VE node to create the VM on. The source template must be on this node."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", var.node_name))
    error_message = "The node_name must be a non-empty Proxmox node name and contain no whitespace."
  }
}

variable "template_id" {
  description = "Identifier of the existing cloud-init template to clone."
  type        = number

  validation {
    condition     = var.template_id == floor(var.template_id) && var.template_id >= 100 && var.template_id <= 999999999
    error_message = "The template_id must be a whole number in the Proxmox range 100 to 999999999."
  }
}

variable "datastore_id" {
  description = "Datastore to place the cloned disks and the cloud-init drive on."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", var.datastore_id))
    error_message = "The datastore_id must be a non-empty Proxmox datastore identifier and contain no whitespace."
  }
}

variable "cpu_cores" {
  description = "Number of CPU cores to give the VM."
  type        = number

  validation {
    condition     = var.cpu_cores == floor(var.cpu_cores) && var.cpu_cores >= 1
    error_message = "The cpu_cores value must be a whole number of at least 1."
  }
}

variable "memory_mib" {
  description = "Dedicated memory to give the VM, in MiB."
  type        = number

  validation {
    condition     = var.memory_mib == floor(var.memory_mib) && var.memory_mib >= 1
    error_message = "The memory_mib value must be a whole number of MiB of at least 1."
  }
}

variable "network_bridge" {
  description = "Proxmox network bridge to attach the VM's single network device to, such as vmbr0."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9._-]{0,14}$", var.network_bridge))
    error_message = "The network_bridge must be a Linux interface name: a letter followed by at most 14 letters, digits, dots, hyphens, or underscores."
  }
}

variable "ipv4_address_cidr" {
  description = "Static IPv4 address for the VM in CIDR notation, such as 192.0.2.10/24. DHCP and IPv6 are out of scope for this module."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ipv4_address_cidr))
    error_message = "The ipv4_address_cidr must be an IPv4 address with a prefix length, such as 192.0.2.10/24."
  }
}

variable "ipv4_gateway" {
  description = "IPv4 default gateway for the VM, without a prefix length."
  type        = string

  validation {
    condition     = can(cidrnetmask("${var.ipv4_gateway}/32"))
    error_message = "The ipv4_gateway must be a bare IPv4 address, such as 192.0.2.1."
  }
}

variable "dns_servers" {
  description = "IPv4 DNS servers for the guest, in order of preference."
  type        = list(string)

  validation {
    condition     = length(var.dns_servers) >= 1
    error_message = "At least one DNS server is required."
  }

  validation {
    condition     = alltrue([for server in var.dns_servers : can(cidrnetmask("${server}/32"))])
    error_message = "Every DNS server must be a bare IPv4 address, such as 192.0.2.53."
  }
}

variable "username" {
  description = "Username of the bootstrap account cloud-init creates in the guest. Continuing ownership of guest users belongs to the consumer's configuration management, not to this module."
  type        = string

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.username))
    error_message = "The username must be a lowercase account name of at most 32 characters, starting with a letter or underscore."
  }
}

variable "ssh_public_keys" {
  description = "OpenSSH public keys authorized for the bootstrap account. Public keys only: this module never accepts private key material."
  type        = list(string)

  validation {
    condition     = length(var.ssh_public_keys) >= 1
    error_message = "At least one SSH public key is required, because the bootstrap account has no password."
  }

  validation {
    condition = alltrue([
      for key in var.ssh_public_keys :
      can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)|sk-ssh-ed25519@openssh\\.com|sk-ecdsa-sha2-nistp256@openssh\\.com) [A-Za-z0-9+/]+={0,3}( |$)", trimspace(key)))
    ])
    error_message = "Every entry must be an OpenSSH public key line, such as \"ssh-ed25519 AAAA... comment\"."
  }
}

variable "vm_id" {
  description = "Identifier to give the VM. Proxmox assigns the next free identifier when this is null."
  type        = number
  default     = null

  validation {
    condition     = var.vm_id == null || (var.vm_id == floor(var.vm_id) && var.vm_id >= 100 && var.vm_id <= 999999999)
    error_message = "The vm_id must be null or a whole number in the Proxmox range 100 to 999999999."
  }
}

variable "guest_agent_enabled" {
  description = "Whether to attach the guest-agent channel to the VM. The default attaches it, so the guest's qemu-guest-agent service has the device it binds to and can be started as soon as the package is installed. Setting this to false produces a VM in which the guest agent cannot run, and attaching the channel afterwards requires stopping and starting the VM, because Proxmox does not hot-plug the change."
  type        = bool
  default     = true
}

variable "stop_on_destroy" {
  description = "Whether destroy stops the VM instead of requesting a guest shutdown. The default stops it, which does not depend on ACPI or on a guest agent but can interrupt workloads and lose unwritten data. Setting it to false requests a shutdown instead, which accepts a destroy that can block or time out when the guest does not shut down."
  type        = bool
  default     = true
}

variable "ssh_port" {
  description = "TCP port to publish in the connection output. This is composition metadata only: the module does not configure the guest's SSH service."
  type        = number
  default     = 22

  validation {
    condition     = var.ssh_port == floor(var.ssh_port) && var.ssh_port >= 1 && var.ssh_port <= 65535
    error_message = "The ssh_port must be a whole number in the range 1 to 65535."
  }
}
