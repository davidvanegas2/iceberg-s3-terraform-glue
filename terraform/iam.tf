resource "aws_iam_role" "glue_service_role" {
  name = "glue_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "glue_service_role_policy" {
  name        = "glue_policy"
  description = "Policy for Glue Role to access S3 scripts bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ]
        Effect = "Allow"
        Resource = [
          "*" # Replace with your S3 scripts bucket ARN
        ]
      },
      {
        Action = [
          "glue:*"
        ],
        Effect   = "Allow",
        Resource = ["*"]
      },
      {
        Action = [
          "cloudwatch:*"
        ]
        Effect   = "Allow",
        Resource = ["*"]
      },
      {
        Action = [
          "logs:*"
        ],
        Effect   = "Allow",
        Resource = ["*"]
      },
      {
        Action   = ["*"],
        Effect   = "Allow",
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_role_policy_attachment" {
  role       = aws_iam_role.glue_service_role.id
  policy_arn = aws_iam_policy.glue_service_role_policy.arn
}

# Create an IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Create an IAM policy for Lambda to read from S3
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-s3-read-policy"
  description = "Policy for Lambda to read from S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "athena:*"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "glue:*"
        ],
        "Resource" : "*"
    }]
  })
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}
