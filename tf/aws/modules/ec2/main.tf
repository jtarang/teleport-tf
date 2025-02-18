resource "aws_instance" "ec2_instance" {
  ## AMI and Instance Type defined in the `launch template`  
  #ami                    = var.image_id  
  #instance_type          = var.instance_type

  # Use the Launch Template
  launch_template {
    id = var.launch_template_id
    version              = "$Latest"
  }

  key_name              = var.ssh_key_name
  security_groups       = var.nsg_ids
  subnet_id             = var.public_subnet_id

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-ec2"
  })

  #user_data = file(var.ec2_bootstrap_script_path)
}
