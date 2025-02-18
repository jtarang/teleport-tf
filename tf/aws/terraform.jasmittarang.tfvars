aws_region                = "us-west-1"
vpc_cidr_block            = "10.0.0.0/16"
public_subnet_cidr        = "10.0.1.0/24"
private_subnet_cidr       = "10.0.2.0/24"
ssh_key_name              = "jasmit-ssh-key"
map_public_ip_on_launch   = true
availability_zone         = "us-west-1a"
ec2_instance_type         = "t2.micro"
ec2_image_id              = ""  # Leave empty for dynamic selection via AWS API
user_prefix               = "jasmit-se-demo"
ec2_asg_desired_capacity  = 1
ec2_asg_max_size          = 2
ec2_asg_min_size          = 1
ec2_bootstrap_script_path = "../../scripts/remote/install-teleport.sh"

tags = {
  "teleport.dev/creator" = "jasmit.tarang@goteleport.com"
  "Owner"                = "Jasmit Tarang"
  "Team"                 = "Solutions Engineering"
}
