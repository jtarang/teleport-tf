data "aws_ssm_parameter" "mongo_host" {
  name = var.mongodb_uri_parameter_store_key
}

data "aws_ssm_parameter" "windows_ad_domain_name" {
  name = var.windows_ad_domain_name_parameter_store_key
}

data "aws_ssm_parameter" "windows_ad_admin_username" {
  name = var.windows_ad_admin_username_parameter_store_key
}

data "aws_ssm_parameter" "windows_ad_admin_password" {
  name = var.windows_ad_admin_password_parameter_store_key
}

locals {
  development_tag = "dev"
  staging_tag = "stg"
  production_tag = "prd"
}

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

module "dev_linux_launch_template" {
  source                    = "./modules/aws/launch_template"
  launch_template_prefix    = "${local.development_tag}-${var.user_prefix}-linux"
  image_id                  = var.linux_ec2_image_id
  instance_type             = var.linux_ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.linux_ec2_bootstrap_script_path
  ec2_ami_ssm_parameter     = var.linux_ec2_ami_ssm_parameter
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
  database_name = module.rds.db_instance.db_name
  database_protocol = module.rds.db_instance.engine
  database_uri = module.rds.db_instance.endpoint
  database_teleport_admin_user = var.rds_db_teleport_admin_user
  database_secret_id = module.rds.db_secret_id
  depends_on = [ module.iam.rds_connect_discovery_role, module.rds.db_instance ]
  mongodb_teleport_display_name = var.mongodb_teleport_display_name
  mongodb_uri = data.aws_ssm_parameter.mongo_host.value
  teleport_display_name_strip_string = var.teleport_display_name_strip_string
  environment_tag = "${local.development_tag}"
}

module "dev_linux_asg" {
  source                   = "./modules/aws/asg"
  ec2_asg_desired_capacity = var.linux_ec2_asg_desired_capacity
  ec2_asg_max_size         = var.linux_ec2_asg_max_size
  ec2_asg_min_size         = var.linux_ec2_asg_min_size
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = [module.vpc.public_subnet_ids[0]]
  launch_template_id       = module.dev_linux_launch_template.launch_template_id
  tags                     = var.tags
  user_prefix              = "${local.development_tag}-${var.user_prefix}-linux"
}


module "prd_linux_launch_template" {
  source                    = "./modules/aws/launch_template"
  launch_template_prefix    = "${local.production_tag}-${var.user_prefix}-linux"
  image_id                  = var.linux_ec2_image_id
  instance_type             = var.linux_ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.linux_ec2_bootstrap_script_path
  ec2_ami_ssm_parameter     = var.linux_ec2_ami_ssm_parameter
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
  database_name = module.rds.db_instance.db_name
  database_protocol = module.rds.db_instance.engine
  database_uri = module.rds.db_instance.endpoint
  database_teleport_admin_user = var.rds_db_teleport_admin_user
  database_secret_id = module.rds.db_secret_id
  depends_on = [ module.iam.rds_connect_discovery_role, module.rds.db_instance ]
  mongodb_teleport_display_name = var.mongodb_teleport_display_name
  mongodb_uri = data.aws_ssm_parameter.mongo_host.value
  teleport_display_name_strip_string = var.teleport_display_name_strip_string
  environment_tag = "${local.production_tag}"
}

module "prd_linux_asg" {
  source                   = "./modules/aws/asg"
  ec2_asg_desired_capacity = var.linux_ec2_asg_desired_capacity
  ec2_asg_max_size         = var.linux_ec2_asg_max_size
  ec2_asg_min_size         = var.linux_ec2_asg_min_size
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = [module.vpc.public_subnet_ids[0]]
  launch_template_id       = module.prd_linux_launch_template.launch_template_id
  tags                     = var.tags
  user_prefix              = "${local.production_tag}-${var.user_prefix}-linux"
}

module "windows_ad_domain_controller_launch_template" {
  source                    = "./modules/aws/launch_template"
  launch_template_prefix    = "${var.user_prefix}-windows-domain-controller"
  image_id                  = var.windows_ec2_image_id
  instance_type             = var.windows_ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id, module.nsg.ad_domain_controller_nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.windows_ad_install_bootstrap_script_path
  ec2_ami_ssm_parameter     = var.windows_ec2_ami_ssm_parameter
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
  windows_ad_domain_name = data.aws_ssm_parameter.windows_ad_domain_name.value
  windows_ad_admin_username = data.aws_ssm_parameter.windows_ad_admin_username.value
  windows_ad_admin_password = data.aws_ssm_parameter.windows_ad_admin_password.value
}

module "windows_ad_node_launch_template" {
  source                    = "./modules/aws/launch_template"
  launch_template_prefix    = "${var.user_prefix}-windows-node"
  image_id                  = var.windows_ec2_image_id
  instance_type             = var.windows_ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id, module.nsg.ad_domain_controller_nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.windows_ad_domain_join_bootstrap_script_path
  ec2_ami_ssm_parameter     = var.windows_ec2_ami_ssm_parameter
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
  windows_ad_domain_name = data.aws_ssm_parameter.windows_ad_domain_name.value
  windows_ad_admin_username = data.aws_ssm_parameter.windows_ad_admin_username.value
  windows_ad_admin_password = data.aws_ssm_parameter.windows_ad_admin_password.value
  windows_ad_domain_controller_ip = module.ad_windows_domain_controller_ec2.private_ip
}

module "ad_windows_domain_controller_ec2" {
  source = "./modules/aws/ec2"
  image_id                  = var.windows_ec2_image_id
  instance_type             = var.windows_ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id, module.nsg.ad_domain_controller_nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.windows_ad_install_bootstrap_script_path
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
  launch_template_id = module.windows_ad_domain_controller_launch_template.launch_template_id
  public_subnet_ids = [module.vpc.public_subnet_ids[0]]
  windows_ad_admin_username = data.aws_ssm_parameter.windows_ad_admin_username.value
  windows_ad_admin_password = data.aws_ssm_parameter.windows_ad_admin_password.value
  windows_ad_domain_name = data.aws_ssm_parameter.windows_ad_domain_name.value
  user_prefix              = "${var.user_prefix}-windows-ad-domain-controller"
}

module "ad_windows_node_ec2" {
  source = "./modules/aws/ec2"
  image_id                  = var.windows_ec2_image_id
  instance_type             = var.windows_ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id, module.nsg.ad_domain_controller_nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.windows_ad_domain_join_bootstrap_script_path
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
  launch_template_id = module.windows_ad_node_launch_template.launch_template_id
  public_subnet_ids = [module.vpc.public_subnet_ids[0]]
  windows_ad_admin_username = data.aws_ssm_parameter.windows_ad_admin_username.value
  windows_ad_admin_password = data.aws_ssm_parameter.windows_ad_admin_password.value
  windows_ad_domain_name = data.aws_ssm_parameter.windows_ad_domain_name.value
  windows_ad_domain_controller_ip = module.ad_windows_domain_controller_ec2.private_ip
  user_prefix              = "${var.user_prefix}-windows-ad-node"
}


# Create a DHCP options set
resource "aws_vpc_dhcp_options" "ad_domain_controller_dns_resolver" {
  domain_name         = data.aws_ssm_parameter.windows_ad_domain_name.value
  domain_name_servers = [
    cidrhost(module.vpc.cidr_block, 2), # AWS default DNS
    module.ad_windows_domain_controller_ec2.private_ip
  ] 
  netbios_node_type = 2
  ntp_servers                       = [module.ad_windows_domain_controller_ec2.private_ip]
  netbios_name_servers              = [module.ad_windows_domain_controller_ec2.private_ip] 

  tags = {
    Name = "${var.user_prefix}-ad-domain-controller-dns-resolver"
  }
}

# Associate the DHCP options set with the VPC
resource "aws_vpc_dhcp_options_association" "dhcp_assoc" {
  vpc_id          = module.vpc.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.ad_domain_controller_dns_resolver.id
}

module "rds" {
  source                 = "./modules/aws/rds"
  rds_db_instance_identifier = "${var.rds_db_instance_identifier}"
  rds_db_username            = var.rds_db_username
  rds_db_teleport_admin_user = var.rds_db_teleport_admin_user
  # DB Password is now managed in secrets manager
  rds_db_name                      = "${var.rds_db_name}"
  rds_db_port                      = var.rds_db_port
  rds_db_instance_class            = var.rds_db_instance_class
  rds_db_allocated_storage         = var.rds_db_allocated_storage
  rds_db_storage_type              = var.rds_db_storage_type
  rds_db_engine                    = var.rds_db_engine
  rds_db_engine_version            = var.rds_db_engine_version
  rds_db_publicly_accessible       = var.rds_db_publicly_accessible
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
