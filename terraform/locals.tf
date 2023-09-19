locals {
  csv_files = {
    customers = var.dummy_data_key_customers,
    orders    = var.dummy_data_key_orders,
    products  = var.dummy_data_key_products,
  }

  sql_files = fileset("../iceberg/initialize/SQL_files/", "*.sql")
}
