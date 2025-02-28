module "external_data" {
  source = "./modules/external_data"
}

module "vpc" {
  source                  = "./modules/vpc"
  tags                    = var.tags
  vpc_cidr_block          = var.vpc_cidr_block
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zones      = var.availability_zones
  user_prefix             = var.user_prefix
}

module "nsg" {
  source         = "./modules/nsg"
  vpc_id         = module.vpc.vpc_id
  user_prefix    = var.user_prefix
  my_external_ip = module.external_data.my_external_ip
  tags           = var.tags
}

module "launch_template" {
  source                    = "./modules/launch_template"
  launch_template_prefix    = var.user_prefix
  image_id                  = var.ec2_image_id
  instance_type             = var.ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.ec2_bootstrap_script_path
  ec2_ami_ssm_parameter     = var.ec2_ami_ssm_parameter
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_version          = var.teleport_version
}

module "asg" {
  source                   = "./modules/asg"
  ec2_asg_desired_capacity = var.ec2_asg_desired_capacity
  ec2_asg_max_size         = var.ec2_asg_max_size
  ec2_asg_min_size         = var.ec2_asg_min_size
  nsg_id                   = module.nsg.nsg_id
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  launch_template_id       = module.launch_template.launch_template_id
  tags                     = var.tags
  user_prefix              = var.user_prefix
}

module "rds_instance" {
  source                 = "./modules/rds"
  rds_db_instance_identifier = var.rds_db_instance_identifier
  rds_db_username            = var.rds_db_username
  # DB Password is now managed in secrets manager
  rds_db_name                      = var.rds_db_name
  rds_db_port                      = var.rds_db_port
  rds_db_instance_class            = var.rds_db_instance_class
  rds_db_allocated_storage         = var.rds_db_allocated_storage
  rds_db_storage_type              = var.rds_db_storage_type
  rds_db_engine                    = var.rds_db_engine
  rds_db_engine_version            = var.rds_db_engine_version
  rds_db_publicly_accessible       = var.rds_db_publicly_accessible
  rds_db_enable_iam_authentication = var.rds_db_enable_iam_authentication
  rds_db_multi_az                  = var.rds_db_multi_az
  rds_db_backup_retention_period   = var.rds_db_backup_retention_period
  rds_db_skip_final_snapshot       = var.rds_db_skip_final_snapshot
  rds_db_storage_encrypted         = var.rds_db_storage_encrypted
  rds_db_parameter_group_name      = var.rds_db_parameter_group_name
  rds_db_security_group_ids        = [module.nsg.nsg_id]
  rds_db_tags                      = var.tags
  rds_db_subnet_group_name         = "${var.user_prefix}-rds-db-group"
  rds_db_subnet_ids                = flatten([module.vpc.public_subnet_ids, module.vpc.private_subnet_ids])
}


module "eks" {
  source                 = "./modules/eks"
  eks_cluster_name       = "${var.user_prefix}-eks"
  eks_cluster_version    = var.eks_cluster_version
  eks_subnet_ids         = flatten([module.vpc.public_subnet_ids, module.vpc.private_subnet_ids]) # Flattening the list of subnet IDs
  eks_security_group_ids = [module.nsg.nsg_id]
  eks_node_instance_type = var.eks_node_instance_type
  eks_node_count         = var.eks_node_desired_capacity
  eks_node_min_size      = var.eks_node_min_capacity
  eks_node_max_size      = var.eks_node_max_capacity
  tags                   = var.tags
}

module "aurora" {
  source                        = "./modules/aurora"
  aurora_cluster_identifier     = var.aurora_cluster_identifier
  aurora_db_username            = var.aurora_db_username
  aurora_db_name                = var.aurora_db_name
  aurora_db_subnet_group_name   = "${var.user_prefix}-aurora-db-group"
  aurora_db_instance_class      = var.aurora_db_instance_class
  aurora_db_publicly_accessible = var.aurora_db_publicly_accessible
  aurora_engine_version         = var.aurora_engine_version
  aurora_engine_type            = var.aurora_engine_type
  aurora_db_security_group_ids  = [module.nsg.nsg_id]
  aurora_db_subnet_ids          = flatten([module.vpc.public_subnet_ids])
  user_prefix                   = var.user_prefix
  aurora_db_tags                = var.tags
}