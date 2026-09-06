# One VM, from the toolkit module in the checkout this repository pins.
#
# `source` is a local path, and it is the whole point of this example. It
# reaches into `vendor/homelab-iac-toolkit/`, the checkout whose revision
# ../toolkit-revision.yml declares, so the module implementation used here is
# the one that single commit selects. The Ansible configuration beside it
# reaches the role in that same checkout, which is what keeps the two halves of
# the toolkit on one revision.
#
# OpenTofu resolves a local `source` relative to the file declaring it, so the
# path is relative to this directory. It cannot be a variable: OpenTofu
# requires a literal module source. Establishing the checkout at that path is
# yours to do, and how you do it is your choice — see the README.
#
# Every value below is fictional or reserved for documentation. The addresses
# come from RFC 5737 and the domain from RFC 2606; none of them names anything
# real, and the SSH key is a throwaway public key from this repository's own
# fixtures whose private half nobody holds. Replace all of them.

module "guest" {
  source = "../vendor/homelab-iac-toolkit/tofu/modules/proxmox-linux-vm"

  name         = "fictional-vm"
  node_name    = "fictional-node"
  template_id  = 9000
  datastore_id = "fictional-datastore"

  cpu_cores      = 2
  memory_mib     = 2048
  network_bridge = "vmbr0"

  ipv4_address_cidr = "192.0.2.10/24"
  ipv4_gateway      = "192.0.2.1"
  dns_servers       = ["192.0.2.53"]

  username        = "fictional"
  ssh_public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"]
}
