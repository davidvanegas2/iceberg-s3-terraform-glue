# iceberg-s3-terraform-glue
Automated setup of Apache Iceberg on Amazon S3 using Terraform. Explore the power of a Lakehouse architecture for data management and analysis, featuring schema discovery, metadata management, and efficient querying with Amazon Athena.

![terraform_architecture drawio (5)](https://github.com/davidvanegas2/iceberg-s3-terraform-glue/assets/46963726/c6c20925-7e9d-4567-a8dd-b7380e20b34a)


# Deploying the Lakehouse
To deploy this data engineering project, follow these steps:

 1. **Configure AWS Profile:** If you haven't already, install the AWS CLI on your machine. In the AWS Management Console, create an IAM user with the necessary permissions for your project. Make sure to generate an access key and secret access key for this user. Open a terminal and run the following command, replacing `<profile-name>`, `<access-key>`, and `<secret-access-key>` with your chosen profile name and IAM user credentials: 
	```shell
	aws configure --profile <profile-name>
	```
	You will be prompted to enter the access key, secret access key, default region, and output format. Fill in the information accordingly.

 2. **Change AWS profile in provider Terraform file:** In the `terraform/provider.tf` file, make sure to use the AWS profile you have configured on your local machine in the last step. This profile should contain the necessary Access Keys and permissions.
	```terraform
	provider "aws" {  
	  region = "us-east-1" # Change this to your desired region  
	  profile = "DUMMY_USER" # Change this to your configured profile 
	}  
	  
	data "aws_caller_identity" "current" {}
	```
 3. **Navigate to Your Terraform Directory:** Open a terminal and navigate to the directory where your Terraform configuration files (usually `.tf` files) are located.
	```shell
	cd terraform
	```

 4. **Initialize Terraform:** Run the following command to initialize Terraform:
	```shell
	terraform init
	```
	 This command downloads the required provider plugins and prepares Terraform for deployment.

 5. **Run Terraform Plan:** Execute the following command:
	```shell
	terraform plan 
	```
	Terraform will analyze your configuration and display a summary of the proposed changes without actually making any modifications to your infrastructure.
	By carefully reviewing the Terraform plan, you can ensure that the proposed changes align with your infrastructure goals. If everything looks as expected, you can proceed with applying the changes using `terraform apply`. If not, you may need to adjust your Terraform configuration before applying the changes.

 6. **Apply Terraform Configuration:** Now execute the following command:
	```shell
	terraform apply
	```
	 Review the changes and confirm by typing `yes` when prompted. Terraform will start provisioning the defined AWS resources.

 7. **Check Lambda Function:** After deploying your resources using Terraform, it's essential to confirm that the Lambda function has been executed correctly. First, open the AWS Management Console, then navigate to the Athena service and select the `lakehouse` workgroup. Look for the following tables:
    1.  `customers`
    2.  `orders`
    3.  `products`

	These tables should be visible in the "lakehouse" workgroup. If they are present, it indicates that the Lambda function responsible for table creation has been executed successfully.
 ![image](https://github.com/davidvanegas2/iceberg-s3-terraform-glue/assets/46963726/cd85080e-0016-4966-af50-c2c7ed2785de)
 If the tables are not visible:
	  - **Check CloudWatch Logs:** Navigate to the CloudWatch service and inspect the logs for any error messages or issues that might have occurred during the Lambda execution.
	  - **Review Terraform Logs:** In your terminal, review the Terraform logs generated during the deployment process. Look for any errors or warnings related to the Lambda function configuration.


 8. **Trigger Glue Job:** After the Lambda function completes successfully, trigger the AWS Glue job created as part of this project. The Glue job will ingest data into the Lakehouse and perform necessary transformations.
	1.  Navigate to the AWS Glue service.
	2.  Locate the "iceberg_init_job" Glue Job
	3.  Select the "iceberg_init_job", and click on the "Action" dropdown menu and choose "Run job."
	4.  Execute with Default Parameters. Click "Run job" to start the data ingestion process.
	5.  Keep an eye on the job status. It should show "**Succeed**" once the job has been completed successfully.

 9. **Athena Query Verification:** To verify that everything is working correctly, navigate to the Athena workgroup named `lakehouse`. Execute queries against any of the three tables that the Glue job created in the Glue Data Catalog. There are some test queries that you can run once you have your Lakehouse deployed and populated with data. These queries are in the `iceberg/test_lakehouse/` folder.
	Example queries:
	 - Fetch data from a table
		```sql
		SELECT *
		FROM "iceberg_lakehouse"."products";
		```
	- Joining orders and customers tables
		```sql
		SELECT *
		FROM "iceberg_lakehouse"."customers" AS customers 
		JOIN "iceberg_lakehouse"."orders" AS orders 
		ON customers.customer_id = orders.customer_id;
		```
	- If you want to see more use cases and how to run them in your Lakehouse you can go to my post which has more examples: 

With these steps, you will have deployed and tested your data engineering project, harnessing the power of Terraform, AWS Lambda, Glue, and Athena to manage and analyze data efficiently. Happy data engineering!



> Written with [StackEdit](https://stackedit.io/).
