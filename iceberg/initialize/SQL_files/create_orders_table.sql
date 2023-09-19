-- Create the Iceberg table for orders
CREATE TABLE IF NOT EXISTS iceberg_lakehouse.orders (
    order_id INT,
    order_date DATE,
    customer_id INT,
    total_amount DOUBLE)
PARTITIONED BY (order_date)
LOCATION 's3://%LAKEHOUSE_BUCKET%/iceberg-output/orders/'
TBLPROPERTIES (
    'table_type'='ICEBERG',
    'format'='parquet');
