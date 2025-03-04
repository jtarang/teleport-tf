variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "A list of availability zones to create subnets in"
  type        = list(string)
}

variable "map_public_ip_on_launch" {
  description = "Whether instances in the subnet should automatically receive a public IP on launch"
  type        = bool
}

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
}
