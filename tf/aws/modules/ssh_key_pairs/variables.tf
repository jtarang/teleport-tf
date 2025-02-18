variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
}
