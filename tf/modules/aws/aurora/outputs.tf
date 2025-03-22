output "aurora_cluster_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}

output "aurora_instance_endpoint" {
  value = aws_rds_cluster_instance.aurora_instance.endpoint
}

output "aurora_db_secret_id" {
  value = data.aws_secretsmanager_secret.master_aurora_secret.id
}
