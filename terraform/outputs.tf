output "lakehouse_bucket_name" {
  value = aws_s3_bucket.lakehouse_bucket.id
}

output "lakehouse_script_bucket_name" {
  value = aws_s3_bucket.lakehouse_scripts_bucket.id
}

output "glue_service_role_arn" {
  value = aws_iam_role.glue_service_role.arn
}

output "glue_script" {
  value = aws_s3_object.lakehouse_job_bucket_object.key
}
