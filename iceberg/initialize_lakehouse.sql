-- Create the lakehouse database if it doesn't exist in the Glue Data Catalog
CREATE DATABASE IF NOT EXISTS iceberg_lakehouse;

-- Create the Iceberg table for customers
CREATE TABLE IF NOT EXISTS iceberg_lakehouse.customers (
    customer_id INT,
    first_name STRING,
    last_name STRING,
    email STRING,
    city STRING)
PARTITIONED BY (city)
LOCATION 's3://<your-bucket-name>/lakehouse/customers'
TBLPROPERTIES (
    'table_type'='ICEBERG',
    'format'='parquet'
    'write_target_data_file_size_bytes'='536870912');

-- Create the Iceberg table for orders
CREATE TABLE IF NOT EXISTS iceberg_lakehouse.orders (
    order_id INT,
    order_date DATE,
    customer_id INT,
    total_amount DOUBLE)
PARTITIONED BY (order_date)
LOCATION 's3://<your-bucket-name>/lakehouse/orders'
TBLPROPERTIES (
    'table_type'='ICEBERG',
    'format'='parquet'
    'write_target_data_file_size_bytes'='536870912');

-- Create the Iceberg table for products
CREATE TABLE IF NOT EXISTS iceberg_lakehouse.products (
    product_id INT,
    product_name STRING,
    category STRING,
    price DOUBLE)
PARTITIONED BY (category)
LOCATION 's3://<your-bucket-name>/lakehouse/products'
TBLPROPERTIES (
    'table_type'='ICEBERG',
    'format'='parquet'
    'write_target_data_file_size_bytes'='536870912');
