resource "random_id" "lakehouse_bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "lakehouse_bucket" {
  bucket = "lakehouse-bucket-${var.environment_name}-${data.aws_caller_identity.current.account_id}-${random_id.lakehouse_bucket_id.hex}"
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
  bucket = "lakehouse-scripts-bucket-${data.aws_caller_identity.current.account_id}-${random_id.lakehouse_bucket_id.hex}"
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

  sql_files = fileset("../iceberg/initialize/SQL_files/", "*.sql")
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
  key          = "iceberg/initialize/SQL_files/${each.value}"
  source       = "../iceberg/initialize/SQL_files/${each.value}"
  content_type = "application/sql"
}

resource "aws_s3_bucket" "results_athena_bucket" {
  bucket = "athena-results-${data.aws_caller_identity.current.account_id}-${random_id.lakehouse_bucket_id.hex}"
}
