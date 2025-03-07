module "external_data" {
  source = "./modules/external_data"
}

module "teleport" {
  source = "./modules/teleport"
}

module "vpc" {
  source                  = "./modules/aws/vpc"
  tags                    = var.tags
  vpc_cidr_block          = var.vpc_cidr_block
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zones      = var.availability_zones
  user_prefix             = var.user_prefix
}

module "nsg" {
  source         = "./modules/aws/nsg"
  vpc_id         = module.vpc.vpc_id
  user_prefix    = var.user_prefix
  vpc_cidr_block = var.vpc_cidr_block
  my_external_ip = module.external_data.my_external_ip
  tags           = var.tags
}

module "iam" {
  source = "./modules/aws/iam"
  iam_role_and_policy_prefix = var.iam_role_and_policy_prefix
}

module "windows_launch_template" {
  source                    = "./modules/aws/launch_template"
  launch_template_prefix    = "${var.user_prefix}-windows"
  image_id                  = var.ec2_image_id
  instance_type             = var.ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id, module.nsg.ad_domain_controller_nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.windows_ec2_bootstrap_script_path
  ec2_ami_ssm_parameter     = var.windows_ec2_ami_ssm_parameter
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
}

module "windows_asg" {
  source                   = "./modules/aws/asg"
  ec2_asg_desired_capacity = var.windows_ec2_asg_desired_capacity
  ec2_asg_max_size         = var.windows_ec2_asg_max_size
  ec2_asg_min_size         = var.windows_ec2_asg_min_size
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  launch_template_id       = module.launch_template.launch_template_id
  tags                     = var.tags
  user_prefix              = var.user_prefix
}

module "linux_launch_template" {
  source                    = "./modules/aws/launch_template"
  launch_template_prefix    = "${var.user_prefix}-linux"
  image_id                  = var.ec2_image_id
  instance_type             = "t2.micro"
  nsg_ids                   = [module.nsg.nsg_id]
  ssh_key_name              = var.ssh_key_name
  ec2_bootstrap_script_path = var.linux_ec2_bootstrap_script_path
  ec2_ami_ssm_parameter     = var.linux_ec2_ami_ssm_parameter
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
}
module "linux_asg" {
  source                   = "./modules/aws/asg"
  ec2_asg_desired_capacity = var.linux_ec2_asg_desired_capacity
  ec2_asg_max_size         = var.linux_ec2_asg_max_size
  ec2_asg_min_size         = var.linux_ec2_asg_min_size
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  launch_template_id       = module.launch_template.launch_template_id
  tags                     = var.tags
  user_prefix              = var.user_prefix
}

# module "rds" {
#   source                 = "./modules/aws/rds"
#   rds_db_instance_identifier = var.rds_db_instance_identifier
#   rds_db_username            = var.rds_db_username
#   # DB Password is now managed in secrets manager
#   rds_db_name                      = var.rds_db_name
#   rds_db_port                      = var.rds_db_port
#   rds_db_instance_class            = var.rds_db_instance_class
#   rds_db_allocated_storage         = var.rds_db_allocated_storage
#   rds_db_storage_type              = var.rds_db_storage_type
#   rds_db_engine                    = var.rds_db_engine
#   rds_db_engine_version            = var.rds_db_engine_version
#   rds_db_publicly_accessible       = var.rds_db_publicly_accessible
#   rds_db_multi_az                  = var.rds_db_multi_az
#   rds_db_backup_retention_period   = var.rds_db_backup_retention_period
#   rds_db_skip_final_snapshot       = var.rds_db_skip_final_snapshot
#   rds_db_storage_encrypted         = var.rds_db_storage_encrypted
#   rds_db_parameter_group_name      = var.rds_db_parameter_group_name
#   rds_db_security_group_ids        = [module.nsg.nsg_id]
#   rds_db_tags                      = var.tags
#   rds_db_subnet_group_name         = "${var.user_prefix}-rds-db-group"
#   rds_db_subnet_ids                = flatten([module.vpc.public_subnet_ids, module.vpc.private_subnet_ids])
# }


# module "eks" {
#   source                 = "./modules/aws/eks"
#   eks_cluster_name       = "${var.user_prefix}-eks"
#   eks_cluster_version    = var.eks_cluster_version
#   eks_subnet_ids         = flatten([module.vpc.public_subnet_ids, module.vpc.private_subnet_ids]) # Flattening the list of subnet IDs
#   eks_security_group_ids = [module.nsg.nsg_id]
#   eks_node_instance_type = var.eks_node_instance_type
#   eks_node_count         = var.eks_node_desired_capacity
#   eks_node_min_size      = var.eks_node_min_capacity
#   eks_node_max_size      = var.eks_node_max_capacity
#   tags                   = var.tags
# }
