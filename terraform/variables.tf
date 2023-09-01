variable "lakehouse_database_name" {
  description = "The name of the database to create"
  type        = string
  default     = "lakehouse"
}

variable "lakehouse_table_name" {
  description = "The name of the table to create"
  type        = string
  default     = "table_v1"
}

variable "dummy_data_s3_key" {
  description = "The S3 key of the dummy data to load"
  type        = string
  default     = "data/dummy_data.csv"
}
