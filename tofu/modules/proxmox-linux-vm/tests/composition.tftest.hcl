# Evidence that the module's connection descriptor composes into ordinary
# consumer-controlled Ansible inventory.
#
# The provider is mocked, so this reads no OpenTofu state, contacts no Proxmox
# endpoint, connects to no guest, and runs no Ansible. It proves one thing: the
# three values the module publishes are exactly the three an ordinary inventory
# needs, and they survive the mapping unchanged.
#
# The composition is the consumer's to perform. Nothing in this repository
# generates inventory, and the Ansible role neither reads this output nor knows
# that OpenTofu exists.
#
# Every value below is fictional or reserved for documentation. The SSH key is
# a throwaway public key generated for these fixtures; nothing holds its
# private half.

mock_provider "proxmox" {}

variables {
  name              = "fictional-vm"
  node_name         = "fictional-node"
  template_id       = 9000
  datastore_id      = "fictional-datastore"
  cpu_cores         = 2
  memory_mib        = 2048
  network_bridge    = "vmbr0"
  ipv4_address_cidr = "192.0.2.10/24"
  ipv4_gateway      = "192.0.2.1"
  dns_servers       = ["192.0.2.53"]
  username          = "fictional"
  ssh_public_keys   = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu7iWiqXXbTjQ5L37P+Vj0mDlDWxowFsZGNXHHLWv91 fictional@example.invalid"]
}

run "the_connection_descriptor_composes_into_ordinary_inventory" {
  command = plan

  assert {
    condition = yamldecode(file("tests/composition-inventory.yml")) == {
      fictional_guests = {
        hosts = {
          "fictional-vm" = {
            ansible_host = output.connection.host
            ansible_user = output.connection.user
            ansible_port = output.connection.port
          }
        }
      }
    }
    error_message = "The connection output must compose into the committed inventory fixture without changing any of its values."
  }
}
