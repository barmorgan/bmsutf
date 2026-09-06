# Plan-only tests (no real resources created)
# Tests verifying bucket generation based on supplied parameters

variables {
  buckets_to_destroy = []
  allow_destroy = false
}

provider "aws" {
  region = "us-east-2"
}

# Test to verify buckets are created based on `buckets` variable and that names are generated correctly
# based on supplied parameters
run "s3_bucket_single" {
  command = plan

  variables {
    buckets = [{name = "bucketname", public = false}]
    company_namespace = "bmtestcomp"
    team_name = "bm-team"
  }

  override_resource {
    target = aws_s3_bucket.team_bucket["bucketname"]
    override_during = plan
    values = {
      id = "bmtestcomp--bm-team--bucketname"
    }
  }

  assert {
    condition = length(keys(aws_s3_bucket.team_bucket)) == 1
    error_message = "one bucket should be created"
  }

  assert {
    condition = contains(keys(aws_s3_bucket.team_bucket), "bucketname")
    error_message = "the bucket should be a for-each resource named 'bucketname'"
  }

  assert {
    condition = "${var.company_namespace}--${var.team_name}--${var.buckets[0].name}" == aws_s3_bucket.team_bucket[var.buckets[0].name].id
    error_message = "bucket name did not match expected pattern"
  }
}