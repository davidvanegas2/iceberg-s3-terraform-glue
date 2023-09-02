"""
Lambda function to run SQL files stored in an S3 bucket on Athena to create Iceberg tables

The mandatory steps are:
1. Read the environment variables which contain the S3 bucket and key of the folder containing the SQL files
2. Read the SQL files from the S3 bucket
3. Run the SQL files on Athena

The mandatory environment variables are:
SCRIPT_BUCKET: The bucket where the SQL files are stored
SCRIPT_KEY: The key of the folder containing the SQL files in the S3 bucket
ATHENA_OUTPUT_LOCATION: The output location of the Athena query results
ATHENA_DATABASE: The name of the database to create
"""

# Import the libraries
import os
import logging

from lambda_run_SQL_files.athena import run_sql_file
from lambda_run_SQL_files.s3 import list_files_in_bucket
from lambda_run_SQL_files.s3 import read_sql_file

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Lambda function to run SQL files stored in an S3 bucket on Athena to create Iceberg tables
    :param event: Unused
    :param context: Unused
    """
    logger.info("Starting the lambda function: lambda_run_SQL_files")
    logger.info("Reading the environment variables")
    # Read the environment variables
    athena_bucket = os.environ["SCRIPT_BUCKET"].strip()
    athena_key = os.environ["SCRIPT_KEY"].strip()
    athena_output_location = os.environ["ATHENA_OUTPUT_LOCATION"].strip()
    athena_database = os.environ["ATHENA_DATABASE"].strip()

    logger.info(f"Environment variables:\n"
                f"athena_bucket: {athena_bucket}\n"
                f"athena_key: {athena_key}\n"
                f"athena_output_location: {athena_output_location}\n"
                f"athena_database: {athena_database}")

    logger.info("Reading the SQL files from the S3 bucket")
    # Read the SQL files from the S3 bucket
    files = list_files_in_bucket(bucket=athena_bucket, prefix=athena_key)

    logger.info("Running the SQL files on Athena")
    # Run the SQL files on Athena
    for file in files:
        logger.info(f"file: {file}")
        sql_file = read_sql_file(bucket=athena_bucket, key=file["Key"])
        run_sql_file(sql_file=sql_file, database_name=athena_database, output_location=athena_output_location)
