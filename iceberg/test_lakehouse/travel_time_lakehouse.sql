UPDATE "iceberg_lakehouse"."products"
SET price = 5
WHERE category = 'Toys';

SELECT *
FROM "iceberg_lakehouse"."products$history";

SELECT *
FROM "iceberg_lakehouse"."products"
FOR VERSION AS OF 151209910305292999; -- Replace with the desired version sequence
