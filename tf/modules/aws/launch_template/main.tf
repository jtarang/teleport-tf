data "aws_region" "current" {}

# Fetch the latest Amazon Linux 2 AMI ID from SSM Parameter Store
data "aws_ssm_parameter" "selected_ami" {
  name = var.ec2_ami_ssm_parameter
}

# Define a local value to conditionally select the image ID
locals {
  selected_image_id = length(var.image_id) > 0 ? var.image_id : data.aws_ssm_parameter.selected_ami.value
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.launch_template_prefix}-instance-profile"
  role = var.iam_instance_role_name
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.launch_template_prefix}-lt"
  image_id      = local.selected_image_id
  instance_type = var.instance_type
    iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }

  tags = merge(var.tags, {
    "Name" = "${var.launch_template_prefix}-lt"
  })

  # Specify the SSH key pair for the instances launched by ASG
  key_name = var.ssh_key_name

  vpc_security_group_ids = var.nsg_ids

  tag_specifications {
    resource_type = "instance"
    tags = merge( { for k, v in var.tags : k == "teleport.dev/creator" ? "instance_metadata_tagging_req" : k => v }, {
      "Name" = "${var.launch_template_prefix}-ec2"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge( { for k, v in var.tags : k == "teleport.dev/creator" ? "instance_metadata_tagging_req" : k => v }, {
      "Name" = "${var.launch_template_prefix}-ebs"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

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
    EC2_INSTANCE_NAME = "${var.launch_template_prefix}-ec2"
    MONGO_DB_URI = var.mongodb_uri
    MONGO_DB_TELEPORT_DISPLAY_NAME = var.mongodb_teleport_display_name
    TELEPORT_DISPLAY_NAME_STRIP_STRING = var.teleport_display_name_strip_string
    WINDOWS_AD_DOMAIN_NAME = var.windows_ad_domain_name
    WINDOWS_AD_ADMIN_USERNAME = var.windows_ad_admin_username
    WINDOWS_AD_ADMIN_PASSWORD = var.windows_ad_admin_password
    WINDOWS_AD_DOMAIN_CONTROLLER_IP = var.windows_ad_domain_controller_ip
    ENVIRONMENT_TAG = var.environment_tag
  }))
}