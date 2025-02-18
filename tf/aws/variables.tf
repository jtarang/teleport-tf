variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

variable "ssh_key_name" {
  description = "Key name for the SSH key"
  default     = "jasmit-ssh-key"
}

variable "map_public_ip_on_launch" {
  description = "Whether instances in the subnet should automatically receive a public IP on launch"
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "The Availability Zone in which to deploy resources."
  type        = string
  default     = "us-west-2a"
}

variable "ec2_instance_type" {
  description = "The instance type for the EC2 instance (e.g., t2.micro, m5.large)"
  type        = string
  default     = "t2.micro"
}

variable "ec2_image_id" {
  description = "The AMI (Amazon Machine Image) ID for the EC2 instance"
  type        = string
  default     = "" # Dynamically selecting the image id using aws api
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
  default     = "jasmit-se-demo"
}

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
  default = {
    "teleport.dev/creator" = "jasmit.tarang@goteleport.com"
    "Owner"                = "Jasmit Tarang"
    "Team"                 = "Solutions Engineering"
  }
}

variable "ec2_asg_desired_capacity" {
  description = "The desired capacity of the Auto Scaling group"
  type        = number
  default     = 1
}

variable "ec2_asg_max_size" {
  description = "The maximum size of the Auto Scaling group"
  type        = number
  default     = 2
}

variable "ec2_asg_min_size" {
  description = "The minimum size of the Auto Scaling group"
  type        = number
  default     = 1
}

variable "ec2_bootstrap_script_path" {
  description = "EC2 bootstrap or cloud-init script path"
  type = string
  default = "../../scripts/remote/install-teleport.sh"
}