resource "aws_athena_workgroup" "lakehouse_workgroup" {
  name          = "lakehouse"
  force_destroy = true
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.results_athena_bucket.bucket}/output/"
    }
  }
}
