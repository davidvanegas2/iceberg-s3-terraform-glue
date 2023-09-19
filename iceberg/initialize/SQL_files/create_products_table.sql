-- Create the Iceberg table for products
CREATE TABLE IF NOT EXISTS iceberg_lakehouse.products (
    product_id INT,
    product_name STRING,
    category STRING,
    price DOUBLE)
PARTITIONED BY (category)
LOCATION 's3://%LAKEHOUSE_BUCKET%/iceberg-output/products/'
TBLPROPERTIES (
    'table_type'='ICEBERG',
    'format'='parquet');
