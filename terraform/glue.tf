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
    "--conf"                             = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions  --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog  --conf spark.sql.catalog.glue_catalog.warehouse=s3://${aws_s3_bucket.lakehouse_bucket.id}/  --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog  --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO"
    "--database_name"                    = var.lakehouse_database_name
    "--dummy_data_bucket"                = aws_s3_bucket.lakehouse_bucket.id
    "--dummy_data_key_orders"            = "raw_input/orders/orders.csv"
    "--dummy_data_key_customers"         = "raw_input/customers/customers.csv"
    "--dummy_data_key_products"          = "raw_input/products/products.csv"
    "--datalake-formats"                 = "iceberg"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.glue_log_group.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
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
  name = var.lakehouse_database_name
}
