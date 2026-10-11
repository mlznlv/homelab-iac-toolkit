# Inputs are consumer-owned. Defaults are limited to behavior that is part of
# the reusable capability rather than to any environment-specific value.

variable "name" {
  description = "Hostname to give the container. It must be a valid DNS name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", var.name)) && length(var.name) <= 253
    error_message = "The name must be a DNS name of at most 253 characters: dot-separated labels of letters, digits, and inner hyphens, each at most 63 characters."
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

  # The upper bound is the provider's own for a container.
  validation {
    condition     = var.cpu_cores == floor(var.cpu_cores) && var.cpu_cores >= 1 && var.cpu_cores <= 128
    error_message = "The cpu_cores value must be a whole number from 1 to 128."
  }
}

variable "memory_mib" {
  description = "Dedicated memory to give the container, in MiB."
  type        = number

  # Proxmox gives a container no less than 16 MiB.
  validation {
    condition     = var.memory_mib == floor(var.memory_mib) && var.memory_mib >= 16
    error_message = "The memory_mib value must be a whole number of MiB of at least 16."
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

  # Written out to Proxmox's own rule rather than delegated to cidrnetmask(),
  # which also accepts an IPv4-mapped IPv6 address, octets with leading zeros,
  # and prefix lengths below 8, none of which Proxmox does. The gateway and DNS
  # server rules below are written out for the same reason.
  validation {
    condition     = can(regex("^((25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])\\.){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])/([89]|[12][0-9]|3[0-2])$", var.ipv4_address_cidr))
    error_message = "The ipv4_address_cidr must be an IPv4 address in dotted decimal, without leading zeros, with a prefix length from 8 to 32, such as 192.0.2.20/24."
  }
}

variable "ipv4_gateway" {
  description = "IPv4 default gateway for the container, without a prefix length."
  type        = string

  validation {
    condition     = can(regex("^((25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])\\.){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])$", var.ipv4_gateway))
    error_message = "The ipv4_gateway must be a bare IPv4 address in dotted decimal, without leading zeros, such as 192.0.2.1."
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
    condition     = alltrue([for server in var.dns_servers : can(regex("^((25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])\\.){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])$", server))])
    error_message = "Every DNS server must be a bare IPv4 address in dotted decimal, without leading zeros, such as 192.0.2.53."
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
      can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)|sk-ssh-ed25519@openssh\\.com|sk-ecdsa-sha2-nistp256@openssh\\.com) [A-Za-z0-9+/]+={0,2}( [^\\r\\n]*)?$", trimspace(key)))
    ])
    error_message = "Every entry must be one OpenSSH public key on a single line, such as \"ssh-ed25519 AAAA... comment\"."
  }
}

variable "container_id" {
  description = "Identifier to give the container. Proxmox assigns the next free identifier when this is null."
  type        = number
  default     = null

  validation {
    # A conditional rather than `||`, so that null never reaches floor():
    # OpenTofu evaluates both sides of `||` before 1.10.
    condition     = var.container_id == null ? true : (var.container_id == floor(var.container_id) && var.container_id >= 100 && var.container_id <= 999999999)
    error_message = "The container_id must be null or a whole number in the Proxmox range 100 to 999999999."
  }
}

variable "nesting_enabled" {
  description = "Whether to enable the Proxmox nesting feature. It defaults to true for systemd-based Debian guests. A later change takes effect on the next container start, and on the provider build this repository locks Proxmox accepts it only from root@pam: see the README."
  type        = bool
  default     = true

  # The provider's own default is false, so a null must not reach the resource.
  nullable = false
}

variable "ssh_port" {
  description = "TCP port to publish in the connection output. This is metadata only; the module does not configure the container's SSH service."
  type        = number
  default     = 22
  nullable    = false

  validation {
    condition     = var.ssh_port == floor(var.ssh_port) && var.ssh_port >= 1 && var.ssh_port <= 65535
    error_message = "The ssh_port must be a whole number in the range 1 to 65535."
  }
}
