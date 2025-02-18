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
  type = string
}
