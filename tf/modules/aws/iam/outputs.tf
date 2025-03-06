output "rds_policy_arn" {
  description = "The ARN of the RDS connection policy"
  value       = aws_iam_policy.rds_policy.arn
}

output "rds_connect_discovery_role" {
  description = "The IAM role for EC2, ECS and RDS"
  value       = aws_iam_role.rds_discovery_role
}

output "rds_role_policy_attachment_id" {
  description = "The ID of the role-policy attachment"
  value       = aws_iam_role_policy_attachment.rds_role_policy_attachment.id
}