SELECT *
FROM "iceberg_lakehouse"."customers" AS customers
JOIN "iceberg_lakehouse"."orders" AS orders
ON customers.customer_id = orders.customer_id;
