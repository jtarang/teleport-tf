variable "rds_db_instance_identifier" {
  description = "The name of the DB instance."
  type        = string
}

variable "rds_db_allocated_storage" {
  description = "The allocated storage for the DB instance."
  type        = number
}

variable "rds_db_storage_type" {
  description = "The storage type for the DB instance."
  type        = string
}

variable "rds_db_subnet_group_name" {
  description = "DB Subnet Group Name"
  type        = string
}

variable "rds_db_engine" {
  description = "The database engine for the instance."
  type        = string
}

variable "rds_db_engine_version" {
  description = "The version of the database engine."
  type        = string
}

variable "rds_db_instance_class" {
  description = "The instance class of the DB instance."
  type        = string
}

# DB Password is now managed
variable "rds_db_username" {
  description = "The master username for the DB instance."
  type        = string
}

variable "rds_db_name" {
  description = "The name of the database to create when the DB instance is created."
  type        = string
}

variable "rds_db_port" {
  description = "The port on which the DB instance will listen."
  type        = number
}

variable "rds_db_publicly_accessible" {
  description = "Indicates whether the DB instance is publicly accessible."
  type        = bool
}

variable "rds_db_backup_retention_period" {
  description = "The backup retention period for the DB instance."
  type        = number
}

variable "rds_db_multi_az" {
  description = "Specifies if the DB instance is a Multi-AZ deployment."
  type        = bool
}

variable "rds_db_skip_final_snapshot" {
  description = "Determines whether a final snapshot is created before the DB instance is deleted."
  type        = bool
}

variable "rds_db_storage_encrypted" {
  description = "Specifies if the DB instance storage is encrypted."
  type        = bool
}

variable "rds_db_enable_iam_authentication" {
  description = "Enables IAM Authentication for RDS"
  type        = bool
}

variable "rds_db_parameter_group_name" {
  description = "The DB parameter group name."
  type        = string
}

variable "rds_db_security_group_ids" {
  description = "List of VPC security group IDs to associate with the DB instance."
  type        = list(string)
}

variable "rds_db_subnet_ids" {
  description = "List of subnet IDs to associate with the DB instance."
  type        = list(string)
}

variable "rds_db_tags" {
  description = "A map of tags to assign to the DB instance."
  type        = map(string)
}
