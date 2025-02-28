variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
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

variable "ssh_key_name" {
  description = "Key name for the SSH key"
}

variable "map_public_ip_on_launch" {
  description = "Whether instances in the subnet should automatically receive a public IP on launch"
  type        = bool
}

variable "ec2_instance_type" {
  description = "The instance type for the EC2 instance (e.g., t2.micro, m5.large)"
  type        = string
}

variable "ec2_image_id" {
  description = "The AMI (Amazon Machine Image) ID for the EC2 instance"
  type        = string
}

variable "user_prefix" {
  description = "User Prefix is used to make the resource owner identifiable"
}

variable "tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
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

variable "ec2_bootstrap_script_path" {
  description = "EC2 bootstrap or cloud-init script path"
  type        = string
}

variable "ec2_ami_ssm_parameter" {
  description = "Path to latest ami SSM parameter"
  type        = string
}

variable "teleport_edition" {
  description = "Teleport Edition to install i.e(cloud, enterprise, oss)"
  type        = string
}

variable "teleport_version" {
  description = "Teleport Version to install"
  type        = string
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "eks_node_instance_type" {
  description = "The EC2 instance type for the EKS node group"
  type        = string
}

variable "eks_node_desired_capacity" {
  description = "The desired number of nodes in the EKS node group"
  type        = number
}

variable "eks_node_min_capacity" {
  description = "The minimum size of the EKS node group"
  type        = number
}

variable "eks_node_max_capacity" {
  description = "The maximum size of the EKS node group"
  type        = number
}

variable "db_instance_identifier" {
  description = "The name of the DB instance."
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage for the DB instance."
  type        = number
}

variable "db_storage_type" {
  description = "The storage type for the DB instance."
  type        = string
}

variable "db_engine" {
  description = "The database engine for the instance."
  type        = string
}

variable "db_engine_version" {
  description = "The version of the database engine."
  type        = string
}

variable "db_instance_class" {
  description = "The instance class of the DB instance."
  type        = string
}

# DB Password is managed now
variable "db_username" {
  description = "The master username for the DB instance."
  type        = string
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created."
  type        = string
}

variable "db_port" {
  description = "The port on which the DB instance will listen."
  type        = number
}

variable "db_publicly_accessible" {
  description = "Indicates whether the DB instance is publicly accessible."
  type        = bool
}

variable "db_backup_retention_period" {
  description = "The backup retention period for the DB instance."
  type        = number
}

variable "db_multi_az" {
  description = "Specifies if the DB instance is a Multi-AZ deployment."
  type        = bool
}

variable "db_skip_final_snapshot" {
  description = "Determines whether a final snapshot is created before the DB instance is deleted."
  type        = bool
}

variable "db_storage_encrypted" {
  description = "Specifies if the DB instance storage is encrypted."
  type        = bool
}

variable "db_parameter_group_name" {
  description = "The DB parameter group name."
  type        = string
}

variable "db_enable_iam_authentication" {
  description = "Enables IAM Authentication for RDS"
  type        = bool
} 