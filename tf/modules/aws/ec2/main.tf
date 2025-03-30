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
  user_data = base64encode(templatefile(var.ec2_bootstrap_script_path, {
    TELEPORT_JOIN_TOKEN = var.teleport_node_join_token
    TELEPORT_EDITION = var.teleport_edition,
    TELEPORT_ADDRESS  = var.teleport_address,
    REGION = data.aws_region.current.name,
    DATABASE_NAME = var.database_name,
    DATABASE_URI = var.database_uri,
    DATABASE_PROTOCOL = var.database_protocol,
    DATABASE_TELEPORT_ADMIN_USER = var.database_teleport_admin_user,
    DATABASE_SECRET_ID = var.database_secret_id,
    EC2_INSTANCE_NAME = "${var.user_prefix}-ec2"
    MONGO_DB_URI = var.mongodb_uri
    MONGO_DB_TELEPORT_DISPLAY_NAME = var.mongodb_teleport_display_name
    TELEPORT_DISPLAY_NAME_STRIP_STRING = var.teleport_display_name_strip_string
    WINDOWS_AD_DOMAIN_NAME = var.windows_ad_domain_name
    WINDOWS_AD_ADMIN_USERNAME = var.windows_ad_admin_username
    WINDOWS_AD_ADMIN_PASSWORD = var.windows_ad_admin_password
    ENVIRONMENT_TAG = var.environment_tag
  }))
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