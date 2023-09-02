"""
Module that handle the S3 bucket operations for the lambda function which runs the SQL files on Athena to create
the Iceberg tables.

Functions in the module:
- list_files_in_bucket: List the files in an S3 bucket in a specific folder
- read_sql_file: Read the SQL file from the S3 bucket
"""

# Import the libraries
import logging
import boto3
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Set up the S3 client
s3_client = boto3.client("s3")


def list_files_in_bucket(bucket: str, prefix: str) -> list:
    """
    List the files in an S3 bucket in a specific folder

    :param bucket: The bucket where the SQL files are stored
    :param prefix: The key of the folder containing the SQL files in the S3 bucket
    :return: The list of files in the S3 bucket
    """
    logger.info("Listing the files in the S3 bucket")
    try:
        response = s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=prefix
        )
        logger.info(f"response: {response}")
        files = response["Contents"]
        logger.info(f"files: {files}")
        return files
    except ClientError as e:
        logger.error(e)
        raise e


def read_sql_file(bucket: str, key: str) -> str:
    """
    Read the SQL file from the S3 bucket

    :param bucket: The bucket where the SQL files are stored
    :param key: The key of the SQL file in the S3 bucket
    :return: The SQL file as a string
    """
    logger.info("Reading the SQL file from the S3 bucket")
    try:
        response = s3_client.get_object(
            Bucket=bucket,
            Key=key
        )
        logger.info(f"response: {response}")
        sql_file = response["Body"].read().decode("utf-8")
        logger.info(f"sql_file: {sql_file}")
        return sql_file
    except ClientError as e:
        logger.error(e)
        raise e
