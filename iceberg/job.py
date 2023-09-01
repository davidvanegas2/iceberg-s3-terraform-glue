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
--table_name: The name of the table to create
--dummy_data_bucket: The bucket where the dummy data is stored
--dummy_data_s3_key: The path to the dummy data to load into the table
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
    "dummy_data_s3_key",
    ])

# Get the arguments
warehouse_bucket = args["warehouse_bucket"].strip()
database_name = args["database_name"].strip()
table_name = args["table_name"].strip()
dummy_data_bucket = args["dummy_data_bucket"].strip()
dummy_data_s3_key = args["dummy_data_s3_key"].strip()

logger.info(f"Glue Job parameters:\n"
            f"warehouse_location: {warehouse_bucket}\n"
            f"database_name: {database_name}\n"
            f"table_name: {table_name}\n"
            f"dummy_data_bucket: {dummy_data_bucket}\n"
            f"dummy_data_s3_key: {dummy_data_s3_key}\n")

conf.set("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
conf.set("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
conf.set("spark.sql.catalog.glue_catalog.warehouse", f"s3://{warehouse_bucket}/")
conf.set("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
conf.set("spark.sql.catalog.glue_catalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
conf.set("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")


def main():
    """
    The main function of the job.
    """
    logger.info("Reading the dummy data from the S3 bucket")
    # Read the dummy data from the S3 bucket
    dummy_data = glue_context.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={
            "paths": [f"s3://{dummy_data_bucket}/{dummy_data_s3_key}"],
            "recurse": True
        },
        format="csv",
        format_options={
            "withHeader": True,
            "separator": ","
        }
    ).toDF()

    logger.info("Appending the dummy data to the Iceberg table")
    # Append the dummy data to the Iceberg table using Data Catalog
    dummy_data.writeTo(f"glue_catalog.{database_name}.{table_name}").append()

    job.commit()


if __name__ == "__main__":
    main()
