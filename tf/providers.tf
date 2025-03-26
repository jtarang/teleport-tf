terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.39"  # Adjust the version as necessary
    }
    teleport = {
      source  = "terraform.releases.teleport.dev/gravitational/teleport"
      version = ">16.0.0"  
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile_name
  default_tags {
    tags = var.tags
  }
}

provider "teleport" {
  alias                 = "gravitational"
  addr                  = var.teleport_address
  identity_file_base64  = var.teleport_identity_file_base64
}