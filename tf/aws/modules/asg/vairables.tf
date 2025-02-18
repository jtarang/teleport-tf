variable "vpc_id" {
  description = "The ID of the VPC where resources will be created"
  type        = string
}

variable "nsg_id" {
  description = "The ID of the security group to be associated with resources"
  type        = string
}

variable "launch_template_id" {
  description = "The ID of the Launch Template for EC2 instances in the Auto Scaling Group"
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the public subnet where EC2 instances will be launched"
  type        = string
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