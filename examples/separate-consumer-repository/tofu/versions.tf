# The provider this configuration uses, and how it is configured.
#
# The module declares the same constraint but no `provider` block, because a
# root module owns provider configuration. This is that root module, so the
# block belongs here.
#
# It is empty on purpose. The endpoint and the credentials that reach it are
# environment-specific and secret, so they never appear in a public example and
# never belong in source control. Supply them at run time through the
# provider's own mechanisms, which the provider documents rather than this
# toolkit. An empty block is valid: every argument the provider accepts is
# optional, and it reads what it needs from the environment.
#
# There is no `backend` block either. This example creates nothing and keeps no
# state worth protecting, so it declares none. That omission is not a
# recommendation to use local state for a real deployment: OpenTofu state
# records what was created and can hold sensitive values, so a real deployment
# chooses its backend and its state-custody policy before its first apply.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111.0"
    }
  }
}

provider "proxmox" {}
