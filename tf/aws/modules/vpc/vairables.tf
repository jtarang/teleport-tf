variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = string
}

variable "map_public_ip_on_launch" {
  description = "Whether instances in the subnet should automatically receive a public IP on launch"
  type        = bool
}

variable "availability_zone" {
  description = "The Availability Zone in which to deploy resources."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
}
