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
  source                     = "./modules/rds"
  db_instance_identifier     = var.db_instance_identifier
  db_username                = var.db_username
  # DB Password is now managed in secrets manager
  db_name                    = var.db_name
  db_port                    = var.db_port
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_storage_type            = var.db_storage_type
  db_engine                  = var.db_engine
  db_engine_version          = var.db_engine_version
  db_publicly_accessible     = var.db_publicly_accessible
  db_enable_iam_authentication = var.db_enable_iam_authentication
  db_multi_az                = var.db_multi_az
  db_backup_retention_period = var.db_backup_retention_period
  db_skip_final_snapshot     = var.db_skip_final_snapshot
  db_storage_encrypted       = var.db_storage_encrypted
  db_parameter_group_name    = var.db_parameter_group_name
  db_security_group_ids      = [module.nsg.nsg_id]
  db_tags                    = var.tags
  db_subnet_group_name       = "${var.user_prefix}-db-group"
  db_subnet_ids              = flatten([module.vpc.public_subnet_ids, module.vpc.private_subnet_ids])
}


module "eks" {
  source = "./modules/eks"


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
