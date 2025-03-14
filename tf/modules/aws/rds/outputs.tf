output "db_instance" {
  description = "The DB object"
  value       = aws_db_instance.default
}

output "db_instance_arn" {
  description = "The ARN of the DB instance."
  value       = aws_db_instance.default.arn
}

output "db_instance_id" {
  description = "The ID of the DB instance."
  value       = aws_db_instance.default.id
}