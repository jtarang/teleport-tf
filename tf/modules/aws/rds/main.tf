data "aws_region" "current" {}

resource "aws_db_subnet_group" "main" {
  name        = "${var.rds_db_subnet_group_name}"
  subnet_ids  = var.rds_db_subnet_ids  # Replace with your subnet IDs

    tags = merge(var.rds_db_tags, {
    Name = "${var.rds_db_subnet_group_name}"
  })
}

resource "aws_db_instance" "default" {
  identifier        = var.rds_db_instance_identifier
  allocated_storage = var.rds_db_allocated_storage
  storage_type      = var.rds_db_storage_type
  engine            = var.rds_db_engine
  engine_version    = var.rds_db_engine_version
  instance_class    = var.rds_db_instance_class
  username          = var.rds_db_username
  manage_master_user_password = true
  db_name           = var.rds_db_name
  port              = var.rds_db_port
  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible = var.rds_db_publicly_accessible
  backup_retention_period = var.rds_db_backup_retention_period
  multi_az          = var.rds_db_multi_az
  skip_final_snapshot = var.rds_db_skip_final_snapshot
  iam_database_authentication_enabled = true
  
  tags = var.rds_db_tags

  # Optional parameters
  storage_encrypted = var.rds_db_storage_encrypted
  parameter_group_name = var.rds_db_parameter_group_name
  vpc_security_group_ids = var.rds_db_security_group_ids
  
}

data "aws_secretsmanager_secret" "master_rds_secret" {
  arn = aws_db_instance.default.master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "master_rds_secret_version" {
  secret_id = data.aws_secretsmanager_secret.master_rds_secret.id
}

#Decode the secret string (which is in JSON format)
locals {
  master_rds_secret_data = jsondecode(data.aws_secretsmanager_secret_version.master_rds_secret_version.secret_string)
}

resource "null_resource" "grant_iam_auth" {
  depends_on = [aws_db_instance.default]

  provisioner "local-exec" {
    command = <<EOT
# Export environment variables for PostgreSQL connection
export PGHOST=${aws_db_instance.default.address}
export PGPORT=${aws_db_instance.default.port}
export PGUSER=${local.master_rds_secret_data["username"]}
export PGPASSWORD='${local.master_rds_secret_data["password"]}'
export PGDATABASE=${var.rds_db_name}
export PGSSLMODE=require

# Run psql command with the exported variables
psql <<SQL
CREATE USER "${var.rds_db_teleport_admin_user}" LOGIN CREATEROLE;
GRANT rds_iam TO "${var.rds_db_teleport_admin_user}" WITH ADMIN OPTION;
GRANT rds_superuser TO "${var.rds_db_teleport_admin_user}";
SQL
  EOT
  }
}