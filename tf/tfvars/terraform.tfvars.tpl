aws_region                = "us-west-1"
vpc_cidr_block            = "10.0.0.0/16"
public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs      = ["10.0.3.0/24", "10.0.4.0/24"]
ssh_key_name              = "../../.ssh/<KEY_NAME>"
map_public_ip_on_launch   = true
availability_zones        = ["us-west-1a", "us-west-1b"]
ec2_instance_type         = "t2.micro"
ec2_image_id              = "" # Leave empty for dynamic selection via AWS API
user_prefix               = "<USER_PREFIX>-se-demo"
ec2_asg_desired_capacity  = 1
ec2_asg_max_size          = 2
ec2_asg_min_size          = 1
ec2_bootstrap_script_path = "../../scripts/remote/install-teleport.sh"
teleport_version          = "<TELEPORT_VERSION_TO_INSTALL>"
teleport_edition          = "<TELEPORT_EDITION_TO_INSTALL>"

eks_cluster_version       = "1.29"
eks_node_instance_type    = "t2.micro"
eks_node_desired_capacity = 1
eks_node_min_capacity     = 1
eks_node_max_capacity     = 2

tags = {
  "teleport.dev/creator" = "<EMAIL>"
  "Owner"                = "<FIRST> <LAST>"
  "Team"                 = "<TEAM NAME>"
}

