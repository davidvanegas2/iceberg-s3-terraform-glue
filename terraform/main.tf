provider "aws" {
  region  = "us-east-1" # Change this to your desired region
  profile = "dvanegas"
}

resource "aws_s3_bucket" "lakehouse_bucket" {
  bucket = "lakehouse-bucket-dvanegas-${random_id.random_id.hex}"
  acl    = "private"
}

resource "aws_s3_bucket" "lakehouse_scripts_bucket" {
  bucket = "lakehouse-scripts-bucket-dvanegas-${random_id.random_id.hex}"
  acl    = "private"
}

resource "aws_s3_bucket_object" "lakehouse_job_bucket_object" {
  bucket = aws_s3_bucket.lakehouse_scripts_bucket.id
  key    = "scripts/job.py"
  source = "iceberg/job.py"

  depends_on = [
    aws_s3_bucket.lakehouse_scripts_bucket
  ]
}

resource "aws_s3_bucket_object" "lakehouse_dummy_data_bucket_object" {
  bucket = aws_s3_bucket.lakehouse_scripts_bucket.id
  key    = var.dummy_data_s3_key
  source = "iceberg/data/dummy_data.csv"

  depends_on = [
    aws_s3_bucket.lakehouse_scripts_bucket
  ]
}

resource "aws_glue_catalog_database" "lakehouse_db" {
  name        = var.lakehouse_database_name
  description = "Lakehouse database"
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
          "arn:aws:s3:::${aws_s3_bucket.lakehouse_scripts_bucket.id}/*"
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

  depends_on = [
    aws_s3_bucket.lakehouse_scripts_bucket,
    aws_iam_role.glue_service_role
  ]
}

resource "aws_iam_role_policy_attachment" "glue_role_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}

resource "aws_glue_job" "iceberg_init_job" {
  name     = "iceberg_init_job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glue_etl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.lakehouse_scripts_bucket.id}/scripts/job.py"
  }

  default_arguments = {
    "warehouse_bucket"  = aws_s3_bucket.lakehouse_bucket.id
    "database_name"     = var.lakehouse_database_name
    "table_name"        = var.lakehouse_table_name
    "dummy_data_bucket" = aws_s3_bucket.lakehouse_scripts_bucket.id
    "dummy_data_s3_key" = var.dummy_data_s3_key
    "datalake-formats"  = "iceberg"
  }

  depends_on = [
    aws_s3_bucket_object.lakehouse_scripts_bucket_object,
    aws_iam_role_policy_attachment.glue_role_policy_attachment,
    aws_glue_catalog_database.lakehouse_db
  ]
}
