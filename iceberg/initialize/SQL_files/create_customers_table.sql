-- Create the Iceberg table for customers
CREATE TABLE IF NOT EXISTS iceberg_lakehouse.customers (
    customer_id INT,
    first_name STRING,
    last_name STRING,
    email STRING,
    city STRING)
PARTITIONED BY (city)
LOCATION 's3://%LAKEHOUSE_BUCKET%/iceberg-output/customers/'
TBLPROPERTIES (
    'table_type'='ICEBERG',
    'format'='parquet',
    'write_target_data_file_size_bytes'='536870912');
