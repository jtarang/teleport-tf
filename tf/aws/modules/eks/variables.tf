variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_cluster_version" {
  description = "The version of the EKS cluster"
  type        = string
}

variable "eks_subnet_ids" {
  description = "The list of subnet IDs to associate with the EKS cluster"
  type        = list(string)
}

variable "eks_security_group_ids" {
  description = "The list of security group IDs to associate with the EKS cluster"
  type        = list(string)
}

variable "eks_node_instance_type" {
  description = "The EC2 instance type for the EKS node group"
  type        = string
}

variable "eks_node_count" {
  description = "The desired number of nodes in the EKS node group"
  type        = number
}

variable "eks_node_min_size" {
  description = "The minimum size of the EKS node group"
  type        = number
}

variable "eks_node_max_size" {
  description = "The maximum size of the EKS node group"
  type        = number
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}
