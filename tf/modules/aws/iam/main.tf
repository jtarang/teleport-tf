# IAM Policy to manage RDS and DB connections
resource "aws_iam_policy" "rds_policy" {
  name        = "${var.iam_role_and_policy_prefix}-rds-connect-policy"
  description = "Policy to allow RDS IAM authentication, connection, and metadata fetch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:ModifyInstanceMetadataOptions",
          "ec2:DeleteTags",
          "ec2:CreateTags"
          ],
        Resource = "*"
      },
      {
        Sid    = "RDSAutoEnableIAMAuth"
        Effect = "Allow"
        Action = [
          "rds:ModifyDBCluster",
          "rds:ModifyDBInstance"
        ]
        Resource = "*"
      },
      {
        Sid      = "RDSConnect"
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "*"
      },
      {
        Sid    = "RDSFetchMetadata"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

# IAM Role Policy to allow EC2 and RDS to assume this role
resource "aws_iam_role" "rds_discovery_role" {
  name = "${var.iam_role_and_policy_prefix}-database-discovery-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "rds.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "rds_role_policy_attachment" {
  role       = aws_iam_role.rds_discovery_role.name
  policy_arn = aws_iam_policy.rds_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.iam_role_and_policy_prefix}-database-discovery-instance-profile"
  role = aws_iam_role.rds_discovery_role.name
}