provider "aws" {
  region = "us-east-1"  # Change this to your desired region
  profile = "dvanegas"
}

resource "aws_s3_bucket" "lakehouse_bucket" {
  bucket = "lakehouse-bucket-dvanegas-${random_id.random_id.hex}"
  acl    = "private"
}
