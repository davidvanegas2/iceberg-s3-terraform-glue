#!/bin/bash

# Get the directory of the script (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the relative path to your Lambda function folder
FUNCTION_FOLDER="src"

# Define the name of the ZIP archive
ZIP_FILE="lambda_function.zip"

# Navigate to the Lambda function folder from the script's directory
cd "$SCRIPT_DIR/$FUNCTION_FOLDER" || exit

# Create a ZIP archive of the entire folder
zip -r "$ZIP_FILE" .

# Move the ZIP archive to the Terraform working directory
mv "$ZIP_FILE" "$SCRIPT_DIR/../../../terraform/"
