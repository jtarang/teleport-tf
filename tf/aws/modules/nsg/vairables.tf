variable "vpc_id" {
  description = "The ID of the VPC where resources will be created"
  type        = string
}


variable "my_external_ip" {
  description = "The public IP address of the user"
  type        = string
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
}


variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}