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
  key    = "iceberg/job.py"
  source = "iceberg/job.py"

  depends_on = [
    aws_s3_bucket.lakehouse_scripts_bucket
  ]
}

locals {
  csv_files = {
    customers = var.dummy_data_key_customers,
    orders    = var.dummy_data_key_orders,
    products  = var.dummy_data_key_products,
  }

  sql_files = [
    "iceberg/initialize/create_database.sql",
    "iceberg/initialize/create_customers_table.sql",
    "iceberg/initialize/create_orders_table.sql",
    "iceberg/initialize/create_products_table.sql",
  ]
}

resource "aws_s3_bucket_object" "csv_objects" {
  for_each = { for category, file in local.csv_files : category => file }

  bucket       = aws_s3_bucket.lakehouse_bucket
  key          = "raw_input/${each.key}/$(basename ${each.value})"
  source       = each.value
  content_type = "text/csv"
}

resource "aws_s3_bucket_object" "sql_objects" {
  for_each = { for file in local.sql_files : file => file }

  bucket       = aws_s3_bucket.lakehouse_scripts_bucket
  key          = each.value
  source       = each.value
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
    "conf"                     = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions  --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog  --conf spark.sql.catalog.glue_catalog.warehouse=s3://${aws_s3_bucket.lakehouse_bucket}/  --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog  --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO"
    "database_name"            = var.lakehouse_database_name
    "dummy_data_bucket"        = aws_s3_bucket.lakehouse_scripts_bucket.id
    "dummy_data_key_orders"    = var.dummy_data_key_orders
    "dummy_data_key_customers" = var.dummy_data_key_customers
    "dummy_data_key_products"  = var.dummy_data_key_products
    "datalake-formats"         = "iceberg"
  }

  depends_on = [
    aws_s3_bucket_object.lakehouse_scripts_bucket_object,
    aws_iam_role_policy_attachment.glue_role_policy_attachment,
    aws_glue_catalog_database.lakehouse_db
  ]
}
