data "aws_region" "current" {}

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
  subnet_id       = var.public_subnet_ids[0]

  tags = merge( { for k, v in var.tags : k == "teleport.dev/creator" ? "instance_metadata_tagging_req" : k => v }, {
    "Name" = "${var.user_prefix}-ec2"
  })
  
  lifecycle {
    ignore_changes = [
      launch_template, # don’t recreate on new LT versions
      security_groups
    ]
  }
}

# Usage example
/*
module "ec2" {
  source = "./modules/aws/ec2"
  image_id                  = var.ec2_image_id
  instance_type             = var.ec2_instance_type
  nsg_ids                   = [module.nsg.nsg_id]
  ssh_key_name              = "${var.ssh_key_name}-${var.aws_region}"
  ec2_bootstrap_script_path = var.ec2_bootstrap_script_path
  tags                      = var.tags
  teleport_edition          = var.teleport_edition
  teleport_address          = var.teleport_address
  teleport_node_join_token  = module.teleport.teleport_join_token
  iam_instance_role_name = module.iam.rds_connect_discovery_role.name
  database_name = module.rds.db_instance.db_name
  database_protocol = module.rds.db_instance.engine
  database_uri = module.rds.db_instance.endpoint
  launch_template_id = module.launch_template.launch_template_id
  public_subnet_id = module.vpc.public_subnet_id
  user_prefix = var.user_prefix
}
*/