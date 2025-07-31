
# 1. Resource registrado: tu bucket de metadatos y tablas
resource "aws_lakeformation_resource" "lakehouse_glue_resource" {
  arn = aws_s3_bucket.lakehouse_bucket.arn
}

resource "aws_lakeformation_permissions" "lakehouse_user_db" {
  principal   = data.aws_caller_identity.current.arn
  permissions = ["ALL"]
  table {
    database_name = aws_glue_catalog_database.iceberg_lakehouse_database.name
    wildcard      = true
  }
}

# 2. Permisos sobre la base de datos Glue
resource "aws_lakeformation_permissions" "lakehouse_glue_db" {
  principal   = aws_iam_role.glue_service_role.arn
  permissions = ["ALL"]
  table {
    database_name = aws_glue_catalog_database.iceberg_lakehouse_database.name
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "lakehouse_lambda_db" {
  principal   = aws_iam_role.lambda_role.arn
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]
  database {
    name       = aws_glue_catalog_database.iceberg_lakehouse_database.name
    catalog_id = "719386081370"
  }
}

# 3. Permisos sobre la ubicación de datos en S3
resource "aws_lakeformation_permissions" "lakehouse_glue_data_loc" {
  principal   = aws_iam_role.glue_service_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_s3_bucket.lakehouse_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "lakehouse_lambda_data_loc" {
  principal   = aws_iam_role.lambda_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_s3_bucket.lakehouse_bucket.arn
  }
}
