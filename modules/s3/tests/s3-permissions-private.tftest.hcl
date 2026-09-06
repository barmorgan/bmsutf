# Apply-based test (real resources created)
# Test that buckets configured to be `public=false` cannot be accessed without credentials

variables {
  buckets = [{name = "bucketname", public = false}]
  team_name = "bm-team"
  buckets_to_destroy = []
  allow_destroy = false
}

provider "aws" {
  region = "us-east-2"
}

run "execute" {
  # no-op - this should run the infrastructure create to prepare other tests
}

# test trying to access a file in the bucket to make sure it is not publicly accessible
run "private_access" {
  variables {
    bucket_id = run.execute.bucket_names["bucketname"]
  }

  module {
    source = "./tests/support/s3-permissions/post"
  }

  assert {
    condition = data.http.public_access.status_code == 403
    error_message = "Unexpected status attempting to retrieve field from private bucket"
  }
}