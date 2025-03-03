variable "lambda_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "lambda_runtime" {
  description = "The runtime environment for the Lambda function"
  type        = string
}

variable "lambda_handler" {
  description = "The function handler for the Lambda function"
  type        = string
}

variable "lambda_role_name" {
  description = "The name of the IAM role for Lambda execution"
  type        = string
}

variable "lambda_policy_name" {
  description = "The name of the IAM policy for Lambda"
  type        = string
}

variable "lambda_environment_variables" {
  description = "Environment variables to be passed to the Lambda function"
  type        = map(string)
}

variable "lambda_tags" {
  description = "A map of tags to apply to the resource"
  type        = map(string)
}
