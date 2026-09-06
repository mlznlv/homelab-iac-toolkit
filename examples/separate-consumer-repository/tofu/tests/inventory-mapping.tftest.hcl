# Evidence that the inventory beside this example is the module's connection
# output, mapped by hand and otherwise unchanged.
#
# The manual mapping is the step this example exists to demonstrate, and prose
# alone would let it drift: an address edited in ../main.tf and not in
# ../../ansible/inventory.yml would leave the example teaching a mapping it no
# longer performs. This asserts the two agree.
#
# The provider is mocked, so nothing here contacts a Proxmox endpoint, holds a
# credential, reads state, or creates anything. It proves that the three
# published values compose into the committed inventory document. It does not
# prove that a VM was created, that the address answers, or that anyone has
# ever run this example against real infrastructure.

mock_provider "proxmox" {}

run "the_committed_inventory_is_the_connection_output_mapped_by_hand" {
  command = plan

  assert {
    condition = yamldecode(file("../ansible/inventory.yml")) == {
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
    error_message = "ansible/inventory.yml must be the module's connection output mapped into ansible_host, ansible_user, and ansible_port, with no value changed."
  }
}
