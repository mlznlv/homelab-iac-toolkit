# What you read after an apply, so you can write the inventory by hand.
#
# The module publishes `connection` as three non-sensitive values: the declared
# address without its prefix, the bootstrap username, and the port it was told
# to advertise. Republishing it here is a convenience for the human doing the
# next step, not a wiring mechanism. Nothing in this example reads this output
# programmatically, nothing generates ../ansible/inventory.yml from it, and
# nothing reads OpenTofu state. You look at it and you type the three values
# into the inventory yourself.

output "connection" {
  description = "Where the bootstrap account can be reached: host, user, and port. Copy these three values into ../ansible/inventory.yml by hand."
  value       = module.guest.connection
}
