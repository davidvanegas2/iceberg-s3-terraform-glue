"""
Module that handle the Athena operations for the lambda function which runs the SQL files on Athena to create
the Iceberg tables.

Functions in the module:
- run_sql_file: Run the SQL file on Athena
"""

# Import the libraries
import logging
import boto3
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Set up the Athena client
athena_client = boto3.client("athena")


def run_sql_file(sql_file: str, database_name: str, output_location: str) -> None:
    """
    Run the SQL file on Athena

    :param sql_file: The SQL file as a string
    :param database_name: The name of the database to create
    :param output_location: The output location of the Athena query results
    :return: None
    :rtype: object
    """
    logger.info("Running the SQL file on Athena")
    try:
        response = athena_client.start_query_execution(
            QueryString=sql_file,
            QueryExecutionContext={
                "Database": database_name
            },
            ResultConfiguration={
                "OutputLocation": output_location
            }
        )
        logger.info(f"response: {response}")
    except ClientError as e:
        logger.error(e)
        raise e
