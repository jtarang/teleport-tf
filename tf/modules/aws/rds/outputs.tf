output "db_instance" {
  description = "The DB object"
  value       = aws_db_instance.demo_rds
}

output "db_instance_arn" {
  description = "The ARN of the DB instance."
  value       = aws_db_instance.demo_rds.arn
}

output "db_instance_id" {
  description = "The ID of the DB instance."
  value       = aws_db_instance.demo_rds.id
}

output "db_secret_id" {
  value = data.aws_secretsmanager_secret.master_rds_secret.id
}