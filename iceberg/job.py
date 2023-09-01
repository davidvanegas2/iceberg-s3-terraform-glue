"""
This Python file is used to ingest data into the Iceberg tables.

It will be run as a job in a Glue job, it will ingest data from S3 raw data bucket and load it into the Iceberg tables.

The mandatory steps are:
1. Read the arguments passed to the job
2. Read the dummy data from the S3 bucket
3. Append the dummy data to the Iceberg table

The mandatory job parameters are:
--warehouse_bucket: The location of the warehouse
--database_name: The name of the database to create
--dummy_data_bucket: The bucket where the dummy data is stored
--dummy_data_key_orders: The key of the dummy data in the S3 bucket
--dummy_data_key_customers: The key of the dummy data in the S3 bucket
--dummy_data_key_products: The key of the dummy data in the S3 bucket
--datalake-formats: The format of the datalake data to load into the table (e.g. Iceberg, delta, hudi)
"""

# Import the libraries
import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from pyspark.conf import SparkConf
from awsglue.job import Job

sc = SparkContext.getOrCreate()
glue_context = GlueContext(sc)
job = Job(glue_context)
spark = glue_context.spark_session
logger = glue_context.get_logger()
conf = SparkConf()

logger.info("Starting Glue job: job.py")
logger.info("Reading the arguments passed to the job")
# Read the arguments passed to the job
args = getResolvedOptions(sys.argv, [
    "warehouse_bucket",
    "database_name",
    "table_name",
    "dummy_data_bucket",
    "dummy_data_key_orders",
    "dummy_data_key_customers",
    "dummy_data_key_products",
    ])

# Get the arguments
warehouse_bucket = args["warehouse_bucket"].strip()
database_name = args["database_name"].strip()
dummy_data_bucket = args["dummy_data_bucket"].strip()
dummy_data_key_orders = args["dummy_data_key_orders"].strip()
dummy_data_key_customers = args["dummy_data_key_customers"].strip()
dummy_data_key_products = args["dummy_data_key_products"].strip()

logger.info(f"Glue Job parameters:\n"
            f"warehouse_location: {warehouse_bucket}\n"
            f"database_name: {database_name}\n"
            f"dummy_data_bucket: {dummy_data_bucket}\n"
            f"dummy_data_key_orders: {dummy_data_key_orders}\n"
            f"dummy_data_key_customers: {dummy_data_key_customers}\n"
            f"dummy_data_key_products: {dummy_data_key_products}\n")


def main():
    """
    The main function of the job.
    """
    logger.info("Reading the dummy data from the S3 bucket")
    # Read the dummy data from the S3 bucket
    data_orders = glue_context.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={
            "paths": [f"s3://{dummy_data_bucket}/{dummy_data_key_orders}"],
            "recurse": True
        },
        format="csv",
        format_options={
            "withHeader": True,
            "separator": ","
        }
    ).toDF()

    data_customers = glue_context.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={
            "paths": [f"s3://{dummy_data_bucket}/{dummy_data_key_customers}"],
            "recurse": True
        },
        format="csv",
        format_options={
            "withHeader": True,
            "separator": ","
        }
    ).toDF()

    data_products = glue_context.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={
            "paths": [f"s3://{dummy_data_bucket}/{dummy_data_key_products}"],
            "recurse": True
        },
        format="csv",
        format_options={
            "withHeader": True,
            "separator": ","
        }
    ).toDF()

    # Create temporary views for the dummy data
    data_orders.createOrReplaceTempView("tmp_dummy_data_orders")
    data_customers.createOrReplaceTempView("tmp_dummy_data_customers")
    data_products.createOrReplaceTempView("tmp_dummy_data_products")

    logger.info("Appending the dummy data to the Iceberg table")
    # Append the dummy data to the Iceberg table using Data Catalog
    query = f"""
        INSERT INTO glue_catalog.{database_name}.orders
        SELECT * FROM tmp_dummy_data_orders
    """
    spark.sql(query)

    query = f"""
        INSERT INTO glue_catalog.{database_name}.customers
        SELECT * FROM tmp_dummy_data_customers
    """
    spark.sql(query)

    query = f"""
        INSERT INTO glue_catalog.{database_name}.products
        SELECT * FROM tmp_dummy_data_products
    """
    spark.sql(query)


if __name__ == "__main__":
    main()
