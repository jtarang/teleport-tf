variable "aws_region" {
  description = "AWS region"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
}

variable "ssh_key_name" {
  description = "Key name for the SSH key"
}

variable "map_public_ip_on_launch" {
  description = "Whether instances in the subnet should automatically receive a public IP on launch"
  type        = bool
}

variable "availability_zone" {
  description = "The Availability Zone in which to deploy resources."
  type        = string
}

variable "ec2_instance_type" {
  description = "The instance type for the EC2 instance (e.g., t2.micro, m5.large)"
  type        = string
}

variable "ec2_image_id" {
  description = "The AMI (Amazon Machine Image) ID for the EC2 instance"
  type        = string
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
}

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}

variable "ec2_asg_desired_capacity" {
  description = "The desired capacity of the Auto Scaling group"
  type        = number
}

variable "ec2_asg_max_size" {
  description = "The maximum size of the Auto Scaling group"
  type        = number
}

variable "ec2_asg_min_size" {
  description = "The minimum size of the Auto Scaling group"
  type        = number
}

variable "ec2_bootstrap_script_path" {
  description = "EC2 bootstrap or cloud-init script path"
  type        = string
}
