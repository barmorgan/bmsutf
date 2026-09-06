# Additional resources to create specifically for tests after the rest of the environment is setup.
# Intended to test the public availability of files in an s3 bucket

terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
      version = "3.4.0"
    }
  }
}


variable "bucket_id" {
  type = string
}

# upload a file into the provided bucket
resource "aws_s3_object" "file_upload" {
  key = "example.txt"
  bucket = var.bucket_id
  source = "./tests/support/s3-permissions/post/example.txt"
}

data "aws_s3_bucket" "bucket" {
  bucket = var.bucket_id
}

# attempt to retrieve the file from the bucket without providing any credentials, testing if access is public or not
data "http" "public_access" {
  # use he regional domain name because the bucket is extremely short lived and if using the global domain name, it may return an HTTP 307
  url = "https://${data.aws_s3_bucket.bucket.bucket_regional_domain_name}/${aws_s3_object.file_upload.key}"
  method = "GET"
}