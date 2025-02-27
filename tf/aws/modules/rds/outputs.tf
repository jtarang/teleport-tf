output "db_instance_endpoint" {
  description = "The endpoint of the DB instance."
  value       = aws_db_instance.default.endpoint
}

output "db_instance_arn" {
  description = "The ARN of the DB instance."
  value       = aws_db_instance.default.arn
}

output "db_instance_id" {
  description = "The ID of the DB instance."
  value       = aws_db_instance.default.id
}
