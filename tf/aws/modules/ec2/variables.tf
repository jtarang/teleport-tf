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

variable "public_subnet_id" {
  description = "The ID of the public subnet where EC2 instances will be launched"
  type        = string
}

variable "ec2_bootstrap_script_path" {
  description = "EC2 bootstrap or cloud-init script path"
  type = string
}

variable "nsg_ids" {
  description = "The ID of the security group to associate with EC2 instances"
  type        = set(string)
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
}