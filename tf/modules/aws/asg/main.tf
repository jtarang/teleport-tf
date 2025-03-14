resource "aws_autoscaling_group" "asg" {
  desired_capacity    = var.ec2_asg_desired_capacity
  max_size            = var.ec2_asg_max_size
  min_size            = var.ec2_asg_min_size
  vpc_zone_identifier = var.public_subnet_ids


  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.user_prefix}-asg-ec2"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
}

# Usage Example
/*
module "asg" {
  source                   = "./modules/aws/asg"
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
*/
