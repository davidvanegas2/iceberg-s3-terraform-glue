provider "aws" {
  region  = "us-east-1" # Change this to your desired region
  profile = "dvanegas"
}

resource "random_id" "lakehouse_bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "lakehouse_bucket" {
  bucket = "lakehouse-bucket-dvanegas-${random_id.lakehouse_bucket_id.hex}"
}

resource "aws_s3_bucket_ownership_controls" "lakehouse_bucket" {
  bucket = aws_s3_bucket.lakehouse_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lakehouse_bucket" {
  bucket = aws_s3_bucket.lakehouse_bucket.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.lakehouse_bucket
  ]
}

resource "aws_s3_bucket" "lakehouse_scripts_bucket" {
  bucket = "lakehouse-scripts-bucket-dvanegas-${random_id.lakehouse_bucket_id.hex}"
}

resource "aws_s3_bucket_ownership_controls" "lakehouse_scripts_bucket" {
  bucket = aws_s3_bucket.lakehouse_scripts_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lakehouse_scripts_bucket" {
  bucket = aws_s3_bucket.lakehouse_scripts_bucket.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.lakehouse_scripts_bucket
  ]
}

resource "aws_s3_object" "lakehouse_job_bucket_object" {
  bucket = aws_s3_bucket.lakehouse_scripts_bucket.id
  key    = "iceberg/ingest_data/job.py"
  source = "${var.project_root}/iceberg/ingest_data/job.py"
}

locals {
  csv_files = {
    customers = var.dummy_data_key_customers,
    orders    = var.dummy_data_key_orders,
    products  = var.dummy_data_key_products,
  }

  sql_files = [
    "iceberg/initialize/SQL_files/create_database.sql",
    "iceberg/initialize/SQL_files/create_customers_table.sql",
    "iceberg/initialize/SQL_files/create_orders_table.sql",
    "iceberg/initialize/SQL_files/create_products_table.sql",
  ]
}

resource "aws_s3_object" "csv_objects" {
  for_each = { for category, file in local.csv_files : category => file }

  bucket       = aws_s3_bucket.lakehouse_bucket.id
  key          = "raw_input/${each.key}/${basename(each.value)}" # basename() is a Terraform function that returns the filename without the path
  source       = "${var.project_root}${each.value}"
  content_type = "text/csv"
}

resource "aws_s3_object" "sql_objects" {
  for_each = { for file in local.sql_files : file => file }

  bucket       = aws_s3_bucket.lakehouse_scripts_bucket.id
  key          = each.value
  source       = "${var.project_root}${each.value}"
  content_type = "application/sql"
}

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
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.lakehouse_bucket.id}/*",
        ]
      },
      {
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:GetConnection",
          "glue:GetTableVersions",
          "glue:GetTableVersion",
          "glue:GetCrawler",
          "glue:SearchTables",
          "glue:GetCatalogImportStatus",
          "glue:GetCrawlers",
          "glue:GetCrawlerMetrics",
          "glue:GetCrawlerVersions"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_role_policy_attachment" {
  role       = aws_iam_role.glue_service_role.id
  policy_arn = aws_iam_policy.glue_service_role_policy.arn
}

resource "aws_glue_job" "iceberg_init_job" {
  name              = "iceberg_init_job"
  role_arn          = aws_iam_role.glue_service_role.arn
  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.lakehouse_scripts_bucket.id}/${aws_s3_object.lakehouse_job_bucket_object.key}"
  }

  default_arguments = {
    "--conf"                     = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions  --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog  --conf spark.sql.catalog.glue_catalog.warehouse=s3://${aws_s3_bucket.lakehouse_bucket.id}/  --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog  --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO"
    "--database_name"            = var.lakehouse_database_name
    "--dummy_data_bucket"        = aws_s3_bucket.lakehouse_scripts_bucket.id
    "--dummy_data_key_orders"    = var.dummy_data_key_orders
    "--dummy_data_key_customers" = var.dummy_data_key_customers
    "--dummy_data_key_products"  = var.dummy_data_key_products
    "--datalake-formats"         = "iceberg"
  }

  depends_on = [
    aws_s3_bucket.lakehouse_bucket,
    aws_s3_bucket.lakehouse_scripts_bucket,
    aws_s3_object.lakehouse_job_bucket_object,
    aws_s3_object.csv_objects,
    aws_s3_object.sql_objects
  ]
}

resource "aws_glue_catalog_database" "iceberg_lakehouse_database" {
  name = "iceberg_lakehouse" # Replace with your desired database name
}

# Define the null_resource to run the script
resource "null_resource" "create_lambda_zip" {
  triggers = {
    # Trigger whenever the contents of the Lambda function folder change
    files = "${path.module}/../iceberg/initialize/lambda_run_SQL_files/src"
  }

  # Use the local-exec provisioner to run the script
  provisioner "local-exec" {
    command = var.path_command_create_zip_lambda
  }
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

# Define the Lambda function resource
resource "aws_lambda_function" "create_iceberg_tables" {
  function_name = "create_iceberg_tables_lambda"
  handler       = "lambda_function.lambda_handler" # Replace with your Lambda function handler
  role          = aws_iam_role.lambda_role.arn

  runtime     = "python3.8"
  memory_size = 256
  timeout     = 10

  # Reference the ZIP archive created by the script
  filename = "lambda_function.zip" # Specify the path to your ZIP archive

  # Define environment variables
  environment {
    variables = {
      SCRIPT_BUCKET          = aws_s3_bucket.lakehouse_scripts_bucket.id,
      SCRIPT_KEY             = "iceberg/initialize/SQL_files/",
      ATHENA_OUTPUT_LOCATION = "s3://${aws_s3_bucket.lakehouse_bucket.id}/athena_output/",
      ATHENA_DATABASE        = aws_glue_catalog_database.iceberg_lakehouse_database.name
      # Add more environment variables as needed
    }
  }

  # Create a dependency link between aws_lambda_function and null_resource
  depends_on = [null_resource.create_lambda_zip]
}
