resource "aws_instance" "ec2_instance" {
  ## AMI and Instance Type defined in the `launch template`  
  #ami                    = var.image_id  
  #instance_type          = var.instance_type

  # Use the Launch Template
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  key_name        = var.ssh_key_name
  security_groups = var.nsg_ids
  subnet_id       = var.public_subnet_id

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-ec2"
  })

  user_data = file(var.ec2_bootstrap_script_path)
}

# Usage example

# module "ec2" {
#   source = "./modules/ec2"
#   launch_template_id = module.launch_template.launch_template_id
#   image_id = var.ec2_image_id
#   tags = var.tags
#   ec2_bootstrap_script_path = var.ec2_bootstrap_script_path
#   ssh_key_name = module.ssh_key_pair.aws_key_pair_name
#   public_subnet_id = module.vpc.public_subnet_id
#   instance_type = var.ec2_instance_type
#   nsg_ids = [module.nsg.nsg_id]
#   user_prefix = var.user_prefix
# }
