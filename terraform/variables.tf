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

variable "dummy_data_key_customers" {
  description = "The S3 key of the dummy data to load"
  type        = string
  default     = "iceberg/dummy_data/customers.csv"
}

variable "dummy_data_key_orders" {
  description = "The S3 key of the dummy data to load"
  type        = string
  default     = "iceberg/dummy_data/orders.csv"
}

variable "dummy_data_key_products" {
  description = "The S3 key of the dummy data to load"
  type        = string
  default     = "iceberg/dummy_data/products.csv"
}
