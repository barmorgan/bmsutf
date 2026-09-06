# Plan-only tests (no real resources created)
# Tests around constraints on module variables

variables {
  team_name = "teamname"
  buckets = [{name = "bucketname", public = false}]
  buckets_to_destroy = []
  allow_destroy = false
}

provider "aws" {
  region = "us-east-2"
}

# tests for team_name variable

run "team_name_too_short" {
  command = plan

  variables {
    team_name = "a"
  }

  expect_failures = [
    var.team_name
  ]
}

run "team_name_has_space" {
  command = plan

  variables {
    team_name = "a c"
  }

  expect_failures = [
    var.team_name
  ]
}

run "team_name_has_slash" {
  command = plan

  variables {
    team_name = "a/c"
  }

  expect_failures = [
    var.team_name
  ]
}

run "team_name_acceptable_3_char" {
  command = plan

  variables {
    team_name = "abc"
  }

  assert {
    condition = var.team_name == "abc"
    error_message = "team_name of 'abc' should be valid"
  }
}

run "team_name_acceptable_long" {
  command = plan

  variables {
    team_name = "abcdefghijklmnopqrstuvwxyz"
  }

  assert {
    condition = var.team_name == "abcdefghijklmnopqrstuvwxyz"
    error_message = "team_name of 'abcdefghijklmnopqrstuvwxyz' should be valid"
  }
}

run "team_name_acceptable_normal" {
  command = plan

  variables {
    team_name = "my-team-1"
  }

  assert {
    condition = var.team_name == "my-team-1"
    error_message = "team_name of 'my-team-1' should be valid"
  }
}

# tests for buckets variable

run "buckets_none_specified" {
  command = plan

  variables {
    buckets = []
  }

  expect_failures = [
    var.buckets
  ]
}

run "buckets_duplicate_names" {
  command = plan

  variables {
    buckets = [{name = "bucket1", public = false}, {name = "bucket2", public = false}, {name = "bucket1", public = false}]
  }

  expect_failures = [
    var.buckets
  ]
}

run "bucket_name_too_short" {
  command = plan

  variables {
    buckets = [{name = "a", public = false}]
  }

  expect_failures = [
    var.buckets
  ]
}

run "bucket_name_has_space" {
  command = plan

  variables {
    buckets = [{name = "a c", public = false}]
  }

  expect_failures = [
    var.buckets
  ]
}

run "bucket_name_has_slash" {
  command = plan

  variables {
    buckets = [{name = "a/c", public = false}]
  }

  expect_failures = [
    var.buckets
  ]
}

run "bucket_name_acceptable_3_char" {
  command = plan

  variables {
    buckets = [{name = "abc", public = false}]
  }

  assert {
    condition = var.buckets[0].name == "abc"
    error_message = "bucket name of 'abc' should be valid"
  }
}

run "bucket_name_acceptable_long" {
  command = plan

  variables {
    buckets = [{name = "abcdefghijklmnopqrstuvwxyz", public = false}]
  }

  assert {
    condition = var.buckets[0].name == "abcdefghijklmnopqrstuvwxyz"
    error_message = "bucket name of 'abcdefghijklmnopqrstuvwxyz' should be valid"
  }
}

run "bucket_name_acceptable_normal" {
  command = plan

  variables {
    buckets = [{name = "my-bucket-3", public = false}]
  }

  assert {
    condition = var.buckets[0].name == "my-bucket-3"
    error_message = "bucket name of 'my-bucket-3' should be valid"
  }
}