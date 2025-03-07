variable "vpc_id" {
  description = "The ID of the VPC where resources will be created"
  type        = string
}

variable "launch_template_id" {
  description = "The ID of the Launch Template for EC2 instances in the Auto Scaling Group"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of IDs of the public subnets where EC2 instances will be launched"
  type        = list(string)
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

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
  default     = "jasmit-se-demo"
}
