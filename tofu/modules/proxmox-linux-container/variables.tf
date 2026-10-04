# Inputs are consumer-owned. Defaults are limited to behavior that is part of
# the reusable capability rather than to any environment-specific value.

variable "name" {
  description = "Hostname to give the container. It must be a valid DNS name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9.-]{0,251}[a-zA-Z0-9])?$", var.name)) && !can(regex("\\.\\.", var.name))
    error_message = "The name must be a non-empty DNS name of at most 253 characters, without whitespace or consecutive dots."
  }
}

variable "node_name" {
  description = "Name of the Proxmox VE node to create the container on."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", var.node_name))
    error_message = "The node_name must be a non-empty Proxmox node name and contain no whitespace."
  }
}

variable "template_file_id" {
  description = "Identifier of the existing Debian container template volume, such as local:vztmpl/debian-13-standard_13.0-1_amd64.tar.zst."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*:[^[:space:]]+$", var.template_file_id))
    error_message = "The template_file_id must be a non-empty Proxmox volume identifier in datastore:path form and contain no whitespace."
  }
}

variable "datastore_id" {
  description = "Datastore for the container root filesystem."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", var.datastore_id))
    error_message = "The datastore_id must be a non-empty Proxmox datastore identifier and contain no whitespace."
  }
}

variable "root_filesystem_size_gb" {
  description = "Root filesystem size in gigabytes."
  type        = number

  validation {
    condition     = var.root_filesystem_size_gb == floor(var.root_filesystem_size_gb) && var.root_filesystem_size_gb >= 1
    error_message = "The root_filesystem_size_gb value must be a whole number of gigabytes of at least 1."
  }
}

variable "cpu_cores" {
  description = "Number of CPU cores to give the container."
  type        = number

  validation {
    condition     = var.cpu_cores == floor(var.cpu_cores) && var.cpu_cores >= 1
    error_message = "The cpu_cores value must be a whole number of at least 1."
  }
}

variable "memory_mib" {
  description = "Dedicated memory to give the container, in MiB."
  type        = number

  validation {
    condition     = var.memory_mib == floor(var.memory_mib) && var.memory_mib >= 1
    error_message = "The memory_mib value must be a whole number of MiB of at least 1."
  }
}

variable "network_bridge" {
  description = "Proxmox network bridge for the container's single veth0 interface."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9._-]{0,14}$", var.network_bridge))
    error_message = "The network_bridge must be a Linux interface name: a letter followed by at most 14 letters, digits, dots, hyphens, or underscores."
  }
}

variable "ipv4_address_cidr" {
  description = "Static IPv4 address for the container in CIDR notation."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ipv4_address_cidr))
    error_message = "The ipv4_address_cidr must be an IPv4 address with a prefix length, such as 192.0.2.20/24."
  }
}

variable "ipv4_gateway" {
  description = "IPv4 default gateway for the container, without a prefix length."
  type        = string

  validation {
    condition     = can(cidrnetmask("${var.ipv4_gateway}/32"))
    error_message = "The ipv4_gateway must be a bare IPv4 address, such as 192.0.2.1."
  }
}

variable "dns_servers" {
  description = "IPv4 DNS servers for the container, in order of preference."
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

variable "ssh_public_keys" {
  description = "OpenSSH public keys installed for root during container creation. Later key rotation belongs to guest configuration."
  type        = list(string)

  validation {
    condition     = length(var.ssh_public_keys) >= 1
    error_message = "At least one SSH public key is required, because the root account has no password."
  }

  validation {
    condition = alltrue([
      for key in var.ssh_public_keys :
      can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)|sk-ssh-ed25519@openssh\\.com|sk-ecdsa-sha2-nistp256@openssh\\.com) [A-Za-z0-9+/]+={0,3}( |$)", trimspace(key)))
    ])
    error_message = "Every entry must be an OpenSSH public key line, such as \"ssh-ed25519 AAAA... comment\"."
  }
}

variable "container_id" {
  description = "Identifier to give the container. Proxmox assigns the next free identifier when this is null."
  type        = number
  default     = null

  validation {
    condition     = var.container_id == null || (var.container_id == floor(var.container_id) && var.container_id >= 100 && var.container_id <= 999999999)
    error_message = "The container_id must be null or a whole number in the Proxmox range 100 to 999999999."
  }
}

variable "nesting_enabled" {
  description = "Whether to enable the Proxmox nesting feature. It defaults to true for systemd-based Debian guests; a later change takes effect on the next container start."
  type        = bool
  default     = true
}

variable "ssh_port" {
  description = "TCP port to publish in the connection output. This is metadata only; the module does not configure the container's SSH service."
  type        = number
  default     = 22

  validation {
    condition     = var.ssh_port == floor(var.ssh_port) && var.ssh_port >= 1 && var.ssh_port <= 65535
    error_message = "The ssh_port must be a whole number in the range 1 to 65535."
  }
}
