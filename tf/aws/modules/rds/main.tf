resource "aws_db_subnet_group" "main" {
  name        = "${var.db_subnet_group_name}"
  subnet_ids  = var.db_subnet_ids  # Replace with your subnet IDs

    tags = merge(var.db_tags, {
    Name = "${var.db_subnet_group_name}"
  })
}


resource "aws_db_instance" "default" {
  identifier        = var.db_instance_identifier
  allocated_storage = var.db_allocated_storage
  storage_type      = var.db_storage_type
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  username          = var.db_username
  manage_master_user_password = true
  db_name           = var.db_name
  port              = var.db_port
  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible = var.db_publicly_accessible
  backup_retention_period = var.db_backup_retention_period
  multi_az          = var.db_multi_az
  skip_final_snapshot = var.db_skip_final_snapshot
  iam_database_authentication_enabled = var.db_enable_iam_authentication

  tags = var.db_tags

  # Optional parameters
  storage_encrypted = var.db_storage_encrypted
  parameter_group_name = var.db_parameter_group_name
  vpc_security_group_ids = var.db_security_group_ids
}