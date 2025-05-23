variable "image_id" {
  description = "The ID of the AMI to launch EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
}

variable "nsg_ids" {
  description = "The ID of the security group to associate with EC2 instances"
  type        = set(string)
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to associate with the EC2 instances"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}

variable "launch_template_prefix" {
  description = "Name prefix for the launch template"
  type        = string
}

variable "ec2_bootstrap_script_path" {
  description = "EC2 bootstrap or cloud-init script path"
  type        = string
}

variable "ec2_ami_ssm_parameter" {
  description = "Path to latest ami SSM parameter"
  type        = string
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

variable "windows_ad_domain_name" {
  description = "Windows AD Domain Name"
  default = ""
}

variable "windows_ad_admin_username" {
  description = "Windows AD Admin Username"
  default = ""
}

variable "windows_ad_admin_password" {
  description = "Windows AD Admin Password"
  default = ""
}

variable "windows_ad_domain_controller_ip" {
  description = "Windows AD Domain Controller IP"
  default = ""
  
}