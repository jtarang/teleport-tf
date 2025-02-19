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

module "ssh_key_pair" {
  source      = "./modules/ssh_key_pairs"
  key_name    = var.ssh_key_name
  tags        = var.tags
  user_prefix = var.user_prefix
}
module "launch_template" {
  source                    = "./modules/launch_template"
  launch_template_prefix    = var.user_prefix
  image_id                  = var.ec2_image_id
  instance_type             = var.ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id]
  ssh_key_name              = module.ssh_key_pair.aws_key_pair_name
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

module "eks" {
  source = "./modules/eks"

  eks_cluster_name       = "${var.user_prefix}-eks"
  eks_cluster_version    = var.eks_cluster_version
  eks_subnet_ids         = flatten([module.vpc.public_subnet_ids, module.vpc.private_subnet_ids]) # Flattening the list of subnet IDs
  eks_node_instance_type = var.eks_node_instance_type
  eks_node_count         = var.eks_node_desired_capacity
  eks_node_min_size      = var.eks_node_min_capacity
  eks_node_max_size      = var.eks_node_max_capacity
  tags                   = var.tags
}
