resource "aws_autoscaling_group" "asg" {
  desired_capacity     = var.ec2_asg_desired_capacity
  max_size             = var.ec2_asg_max_size
  min_size             = var.ec2_asg_min_size
  vpc_zone_identifier  = [var.public_subnet_id]
  
  
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  tag {
    key = "teleport.dev/creator"
    value = "jasmit.tarang@goteleport.com"
    propagate_at_launch = true
  }

  health_check_type          = "EC2"
  health_check_grace_period  = 300
}