resource "aws_cloudwatch_log_group" "glue_log_group" {
  name              = "glue_log_group"
  retention_in_days = 14
}

data "archive_file" "lambda_run_SQL_files" {
  type = "zip"

  source_dir  = "${path.module}/../iceberg/initialize/lambda_run_SQL_files/src"
  output_path = "${path.module}/lambda_function_run_SQL_files.zip"
}
