resource "aws_db_subnet_group" "aurora_db_subnet_group" {
  name       = var.aurora_db_subnet_group_name
  subnet_ids = var.aurora_db_subnet_ids # Replace with your subnet IDs

  tags = merge(var.aurora_db_tags, {
    Name = "${var.aurora_db_subnet_group_name}"
  })
}


resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier                  = var.aurora_cluster_identifier
  engine                              = var.aurora_engine_type
  engine_version                      = var.aurora_engine_version
  master_username                     = var.aurora_db_username
  database_name                       = var.aurora_db_name
  skip_final_snapshot                 = true
  manage_master_user_password         = true # AWS will automatically manage the master password
  iam_database_authentication_enabled = true
  vpc_security_group_ids              = var.aurora_db_security_group_ids
  db_subnet_group_name                = aws_db_subnet_group.aurora_db_subnet_group.name

  tags = merge(var.aurora_db_tags, {
    Name = "${var.user_prefix}-aurora-cluster"
  })
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier  = aws_rds_cluster.aurora_cluster.cluster_identifier
  instance_class      = var.aurora_db_instance_class
  engine              = aws_rds_cluster.aurora_cluster.engine
  publicly_accessible = var.aurora_db_publicly_accessible

  tags = merge(var.aurora_db_tags, {
    Name = "${var.user_prefix}-aurora-cluster-instance"
  })
}

# Usage Example
/*
module "aurora" {
  source                        = "./modules/aurora"
  aurora_cluster_identifier     = var.aurora_cluster_identifier
  aurora_db_username            = var.aurora_db_username
  aurora_db_name                = var.aurora_db_name
  aurora_db_subnet_group_name   = "${var.user_prefix}-aurora-db-group"
  aurora_db_instance_class      = var.aurora_db_instance_class
  aurora_db_publicly_accessible = var.aurora_db_publicly_accessible
  aurora_engine_version         = var.aurora_engine_version
  aurora_engine_type            = var.aurora_engine_type
  aurora_db_security_group_ids  = [module.nsg.nsg_id]
  aurora_db_subnet_ids          = flatten([module.vpc.public_subnet_ids])
  user_prefix                   = var.user_prefix
  aurora_db_tags                = var.tags
}
*/


