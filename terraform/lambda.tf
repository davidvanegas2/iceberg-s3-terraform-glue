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
