# ==============================
# General Configuration
# ==============================
aws_region                = "us-west-1"  # AWS region for resources
user_prefix               = "jasmit-se-demo"  # Prefix for user-specific resources

# Tagging for resources
tags = {
  "teleport.dev/creator" = "jasmit.tarang@goteleport.com"  # Creator's email
  "Owner"                = "Jasmit Tarang"  # Resource owner
  "Team"                 = "Solutions Engineering"  # Team responsible
}

# ==============================
# VPC Configuration
# ==============================
vpc_cidr_block            = "10.0.0.0/16"  # CIDR block for VPC
public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]  # CIDR blocks for public subnets
private_subnet_cidrs      = ["10.0.3.0/24", "10.0.4.0/24"]  # CIDR blocks for private subnets
availability_zones        = ["us-west-1a", "us-west-1b"]  # Availability zones for resource distribution

# ==============================
# EC2 Instance/ASG Configuration
# ==============================
ec2_asg_desired_capacity  = 1  # Desired capacity of EC2 Auto Scaling Group
ec2_asg_min_size          = 1  # Minimum size of EC2 Auto Scaling Group
ec2_asg_max_size          = 2  # Maximum size of EC2 Auto Scaling Group
ec2_bootstrap_script_path = "../../scripts/remote/install-teleport.sh"  # Path to EC2 bootstrap script
ec2_ami_ssm_parameter     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"  # SSM parameter for AMI ID
ec2_instance_type         = "t2.micro"  # EC2 instance type
ec2_image_id              = ""  # Leave empty for dynamic selection via AWS API
ssh_key_name              = "jasmit-us-west-1"  # SSH key name for EC2 access
map_public_ip_on_launch   = true  # Enable public IP mapping on EC2 launch


# ==============================
# Teleport Configuration
# ==============================
# Teleport Configuration for EC2 Instances
teleport_version          = "17.2.7"  # Teleport version to be installed on EC2
teleport_edition          = "enterprise"  # Teleport edition to be used

# ==============================
# EKS Cluster Configuration
# ==============================
eks_cluster_version       = "1.32"  # Kubernetes version for EKS cluster
eks_node_instance_type    = "t2.micro"  # EC2 instance type for EKS worker nodes
eks_node_desired_capacity = 1  # Desired number of worker nodes
eks_node_min_capacity     = 1  # Minimum number of worker nodes
eks_node_max_capacity     = 2  # Maximum number of worker nodes

# ==============================
# Database Instance Configuration
# ==============================
db_instance_identifier     = "jasmit-psql-rds"  # Identifier for RDS instance
db_username                = "jasmit"  # Database username
# db_password is now managed in Secrets Manager
db_name                    = "jasmitTestDb"  # Name of the database
db_port                    = 5432  # Port for database access
db_instance_class          = "db.t4g.micro"  # RDS instance type
db_allocated_storage       = 20  # Storage allocated for the RDS instance in GB
db_storage_type            = "gp2"  # Type of storage for RDS (gp2 for General Purpose SSD)
db_engine                  = "postgres"  # Database engine (PostgreSQL)
db_engine_version          = "17.4"  # Version of PostgreSQL
db_publicly_accessible     = true  # Make the database publicly accessible
db_multi_az                = false  # Multi-AZ for high availability (false = no)
db_backup_retention_period = 7  # Retention period for database backups (in days)
db_skip_final_snapshot     = true  # Skip final snapshot when deleting RDS instance
db_storage_encrypted       = false  # Whether storage should be encrypted
db_parameter_group_name    = "default.postgres17"  # Parameter group for PostgreSQL
db_enable_iam_authentication = true  # Enable IAM authentication for database access