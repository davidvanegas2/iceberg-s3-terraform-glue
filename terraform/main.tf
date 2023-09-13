resource "aws_cloudwatch_log_group" "glue_log_group" {
  name              = "glue_log_group"
  retention_in_days = 14
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
