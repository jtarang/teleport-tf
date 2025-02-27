# ==============================
# General Configuration
# ==============================
aws_region                = "<AWS_REGION>"  # AWS region for resources (e.g., "us-west-1")
user_prefix               = "<USER_PREFIX>-se-demo"  # Prefix for user-specific resources (e.g., "example-user")
tags = {
  "teleport.dev/creator" = "<EMAIL>"  # Creator's email address (e.g., "user@example.com")
  "Owner"                = "<FIRST> <LAST>"  # Resource owner name (e.g., "John Doe")
  "Team"                 = "<TEAM_NAME>"  # Team responsible for resources (e.g., "DevOps Team")
}

# ==============================
# VPC Configuration
# ==============================
vpc_cidr_block            = "10.0.0.0/16"  # CIDR block for VPC (e.g., "10.0.0.0/16")
public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]  # CIDR blocks for public subnets (e.g., ["10.0.1.0/24", "10.0.2.0/24"])
private_subnet_cidrs      = ["10.0.3.0/24", "10.0.4.0/24"]  # CIDR blocks for private subnets (e.g., ["10.0.3.0/24", "10.0.4.0/24"])
availability_zones        = ["us-west-1a", "us-west-1b"]  # Availability zones (e.g., ["us-west-1a", "us-west-1b"])

# ==============================
# EC2 Instance/ASG Configuration
# ==============================
ec2_instance_type         = "t2.micro"  # EC2 instance type (e.g., "t2.micro")
ec2_image_id              = ""  # Leave empty for dynamic selection via AWS API
ssh_key_name              = "../../.ssh/<KEY_NAME>"  # SSH key name (e.g., "../../.ssh/my-key")
map_public_ip_on_launch   = true  # Enable public IP mapping on EC2 instance launch (true/false)

# Auto Scaling Group (ASG) Configuration
ec2_asg_desired_capacity  = 1  # Desired capacity for the EC2 Auto Scaling Group (e.g., 1)
ec2_asg_max_size          = 2  # Maximum size of the EC2 Auto Scaling Group (e.g., 2)
ec2_asg_min_size          = 1  # Minimum size of the EC2 Auto Scaling Group (e.g., 1)
ec2_bootstrap_script_path = "../../scripts/remote/install-teleport.sh"  # Path to EC2 bootstrap script (e.g., "../../scripts/remote/install.sh")

# ==============================
# Teleport Configuration
# ==============================
teleport_version          = "<TELEPORT_VERSION_TO_INSTALL>"  # Teleport version to install (e.g., "20.0.0")
teleport_edition          = "<TELEPORT_EDITION_TO_INSTALL>"  # Teleport edition to install (e.g., "enterprise")

# ==============================
# EKS Cluster Configuration
# ==============================
eks_cluster_version       = "1.32"  # Kubernetes version for EKS cluster (e.g., "1.21")
eks_node_instance_type    = "t2.micro"  # EC2 instance type for EKS worker nodes (e.g., "t3.medium")
eks_node_desired_capacity = 1  # Desired capacity for EKS worker nodes (e.g., 1)
eks_node_min_capacity     = 1  # Minimum number of worker nodes (e.g., 1)
eks_node_max_capacity     = 2  # Maximum number of worker nodes (e.g., 2)

# ==============================
# Database Instance Configuration
# ==============================
db_instance_identifier     = "<DB_INSTANCE_IDENTIFIER>"  # Identifier for RDS instance (e.g., "example-postgres-db")
db_username                = "<DB_USERNAME>"  # Database username (e.g., "admin")
# db_password is now managed in Secrets Manager
db_name                    = "<DB_NAME>"  # Name of the database (e.g., "exampledb")
db_port                    = 5432  # Port for database access (e.g., 5432 for PostgreSQL)
db_instance_class          = "db.t3.small"  # RDS instance type (e.g., "db.t3.small")
db_allocated_storage       = 20  # Storage allocated for the RDS instance in GB (e.g., 20)
db_storage_type            = "gp3"  # Type of storage for RDS (gp3 for General Purpose SSD) (e.g., "gp3")
db_engine                  = "postgres"  # Database engine (e.g., "postgres")
db_engine_version          = "13.4"  # Version of the database engine (e.g., "13.4" for PostgreSQL)
db_publicly_accessible     = true  # Whether the DB is publicly accessible (true/false)
db_multi_az                = true  # Enable Multi-AZ for high availability (true/false)
db_backup_retention_period = 7  # Retention period for database backups in days (e.g., 7 days)
db_skip_final_snapshot     = false  # Skip final snapshot when deleting RDS instance (true/false)
db_storage_encrypted       = true  # Whether to encrypt storage (true/false)
db_parameter_group_name    = "default.postgres13"  # Parameter group for PostgreSQL (e.g., "default.postgres13")
db_enable_iam_authentication = true  # Enable IAM authentication for DB access (true/false)
