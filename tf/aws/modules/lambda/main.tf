resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.lambda_role_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.lambda_policy_name}"
  description = "IAM policy for Lambda to write logs to CloudWatch"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:*"
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.lambda_name}"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "${var.lambda_runtime}"
  handler       = "${var.lambda_handler}"  
  timeout       = 15
  memory_size   = 128
  description   = "Lambda function with no code for future updates"

  filename         = "lambda_handler.zip"
  source_code_hash = filebase64sha256("lambda_handler.zip")

  environment {
    variables = {
      key = "value"
    }
  }

  tags = var.lambda_tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment
  ]
}

# Usage example
# module "lambda" {
#   source = "./modules/lambda"
#   lambda_name = var.lambda_name
#   lambda_handler = var.lambda_handler
#   lambda_policy_name = var.lambda_policy_name
#   lambda_role_name = var.lambda_role_name
#   lambda_runtime = var.lambda_runtime
#   lambda_environment_variables = var.lambda_environment_variables
#   lambda_tags = {}
# }
