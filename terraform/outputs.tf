output "lakehouse_bucket_name" {
  value = aws_s3_bucket.lakehouse_bucket.id
}

output "lakehouse_script_bucket_name" {
  value = aws_s3_bucket.lakehouse_script_bucket.id
}

output "glue_service_role_arn" {
  value = aws_iam_role.glue_service_role.arn
}
