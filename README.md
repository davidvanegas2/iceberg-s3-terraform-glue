# iceberg-s3-terraform-glue
 Automated setup of Apache Iceberg on Amazon S3 using Terraform and AWS Glue Data Catalog. Explore the power of a Lakehouse architecture for data management and analysis, featuring schema discovery, metadata management, and efficient querying with Amazon Athena.

![terraform_architecture drawio (5)](https://github.com/davidvanegas2/iceberg-s3-terraform-glue/assets/46963726/c6c20925-7e9d-4567-a8dd-b7380e20b34a)


# Deploying the Data Engineering Project
To deploy this data engineering project, follow these steps:

1. **Configure AWS Profile:** In the `terraform/provider.tf` file, make sure to use the AWS profile you have configured on your local machine. This profile should contain the necessary Access Keys and permissions.

2. **Initialize Terraform:** Navigate to the terraform folder using your terminal and run the following command to initialize Terraform:
```shell
terraform init
```
 This command downloads the required provider plugins and prepares Terraform for deployment.

3. **Apply Terraform Configuration:** After initializing Terraform, execute the following command:
```shell
terraform apply
```
 Review the changes and confirm by typing `yes` when prompted. Terraform will start provisioning the defined AWS resources.

4. **Check Lambda Function:** Once the Terraform deployment is successful, the Lambda function is already invoked by Terraform at creation time. This function is responsible for creating the Lakehouse tables.

5. **Trigger Glue Job:** After the Lambda function completes successfully, trigger the AWS Glue job created as part of this project. The Glue job will ingest data into the Lakehouse and perform necessary transformations.

6. **Athena Query Verification:** To verify that everything is working correctly, navigate to the Athena workgroup named `lakehouse`. Execute queries against any of the three tables that the Glue job created in the Glue Data Catalog. Ensure that the tables have data after running the Glue job.

With these steps, you will have deployed and tested your data engineering project, harnessing the power of Terraform, AWS Lambda, Glue, and Athena to manage and analyze data efficiently. Happy data engineering!
