terraform {
  required_providers {
    teleport = {
      source  = "terraform.releases.teleport.dev/gravitational/teleport"
      version = ">16.0.0"
    }
  }
}

# Teleport Join Token
resource "random_string" "random_token" {
  length  = 32
  special = false
}

# Registers the Join Token 
resource "teleport_provision_token" "teleport_join_token" {
  version = "v2"

  metadata = {
    name    = random_string.random_token.result
    expires = timeadd(timestamp(), "30m")

    labels = {
      "teleport.dev/origin" = "dynamic" // This label is added on Teleport side by default
    }
  }
  spec = {
    roles = ["Node", "Db", "WindowsDesktop"]

  }
  lifecycle {
    ignore_changes = [
      metadata.expires,
    ]
  }
}