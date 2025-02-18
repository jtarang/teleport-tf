# Fetch the latest Amazon Linux 2 AMI ID from SSM Parameter Store
data "aws_ssm_parameter" "latest_amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Define a local value to conditionally select the image ID
locals {
  selected_image_id = length(var.image_id) > 0 ? var.image_id : data.aws_ssm_parameter.latest_amazon_linux_ami.value
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.launch_template_prefix}-lt"
  image_id      = local.selected_image_id
  instance_type = var.instance_type

  tags = merge(var.tags, {
    "Name" = "${var.launch_template_prefix}-lt"
  })

  # Specify the SSH key pair for the instances launched by ASG
  key_name = var.ssh_key_name

  vpc_security_group_ids = var.nsg_ids

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      "Name" = "${var.launch_template_prefix}-ec2"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      "Name" = "${var.launch_template_prefix}-ebs"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = base64encode(file(var.ec2_bootstrap_script_path))
}
