variable "aurora_cluster_identifier" {
  description = "The identifier for the Aurora DB cluster"
}

variable "aurora_db_username" {
  description = "Database master username"
}

variable "aurora_db_name" {
  description = "The name of the database"
}

variable "aurora_db_subnet_group_name" {
  description = "DB Subnet Group Name"
  type        = string
}

variable "aurora_db_instance_class" {
  description = "The instance class of the DB instance."
  type        = string
}

variable "aurora_db_publicly_accessible" {
  description = "Indicates whether the DB instance is publicly accessible."
  type        = bool
}

variable "aurora_db_security_group_ids" {
  description = "List of VPC security group IDs to associate with the DB instance."
  type        = list(string)
}

variable "aurora_engine_version" {
  description = "The engine version for Aurora"
}

variable "aurora_db_subnet_ids" {
  description = "List of subnet IDs to associate with the DB instance."
  type        = list(string)
}

variable "aurora_db_tags" {
  description = "A map of tags to assign to the DB instance."
  type        = map(string)
}

variable "aurora_engine_type" {
  description = "Aurora Cluster Engine type"
  type        = string
}

variable "user_prefix" {
  description = "User Prefix to indetify resources"
  type        = string
}
