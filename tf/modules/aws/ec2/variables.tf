variable "image_id" {
  description = "The ID of the AMI to launch EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to associate with the EC2 instances"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}

variable "launch_template_id" {
  description = "The ID of the Launch Template for EC2 instances in the Auto Scaling Group"
  type        = string
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnet where EC2 instances will be launched"
  type        = list(string)
}

variable "ec2_bootstrap_script_path" {
  description = "EC2 bootstrap or cloud-init script path"
  type        = string
}

variable "nsg_ids" {
  description = "The ID of the security group to associate with EC2 instances"
  type        = set(string)
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
}

variable "teleport_edition" {
  description = "Teleport Edition to install i.e(cloud, enterprise, oss)"
  type        = string
}

variable "teleport_address" {
  description = "Teleport Domain/Address; this is grabbed from the local env vars from tctl"
  type        = string
}

variable "teleport_node_join_token" {
  description = "Teleport Node Join Token"
  type        = string
}

variable "iam_instance_role_name" {
  description = "The Name of the IAM role to be associated with EC2 instances profile."
  type        = string
}

variable "database_name" {
  description = "The name of the database"
  type        = string
  default     = ""
}

variable "database_uri" {
  description = "The URI of the database"
  type        = string
  default     = ""
}

variable "database_protocol" {
  description = "The protocol used to connect to the database"
  type        = string
  default     = ""
}

variable "database_teleport_admin_user" {
  description = "Teleport Admin User that can create and manage users"
  type        = string
  default     = ""
}

variable "database_secret_id" {
  description = "ID for the database secret"
  default = ""
}

variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  default     = ""
}

variable "mongodb_teleport_display_name" {
  description = "MongoDB Teleport display name"
  type        = string
  default     = ""
}

variable "teleport_display_name_strip_string" {
  description = "Strip any value to node and db names for Teleport Display Names"
  default = " "
}

variable "environment_tag" {
  description = "Environment Tag Value: dev, stg, prd"
  default = "dev" 
}