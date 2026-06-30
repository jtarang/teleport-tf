terraform {
  backend "s3" {
    bucket         = "jasmit-tf-state-bucket"
    key           = "teleport-tf/nebula-dash/terraform.state.tfstate"
    region        = "us-east-1"
    encrypt       = true
  }
}
