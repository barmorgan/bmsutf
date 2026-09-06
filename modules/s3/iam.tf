locals {
  # the common permissions that should be granted on s3 bucket. Defined here because they are used multiple times
  s3_permissions = [
    "s3:PutObject",
    "s3:GetObject",
    "s3:DeleteObject",
    "s3:ListBucket",
  ]
}

# An IAM Role generated that will have read/write permissions to the created buckets
resource "aws_iam_role" "team_role" {
  name = "team-role-${var.team_name}"

  assume_role_policy = data.aws_iam_policy_document.assume_role_trust_policy.json

  tags = {
    Teams = var.team_name
    ManagedModule = "s3"
  }
}

# The access policy containing the s3 permissions that will be associated with the generated role
resource "aws_iam_policy" "team_s3_access" {
  name = "${var.team_name}-s3-buckets-access"
  policy = data.aws_iam_policy_document.access_to_all_team_buckets.json

  tags = {
    Teams = var.team_name
    ManagedModule = "s3"
  }
}

# The actual policy document created for read/write access to the buckets.
data "aws_iam_policy_document" "access_to_all_team_buckets" {
  # Statement granting permissions to the buckets themselves
  statement {
    sid = "BucketAccess"

    actions = local.s3_permissions
    resources = [for i in aws_s3_bucket.team_bucket : "arn:aws:s3:::${i.id}"]
  }

  # Statement granting permissions to items within the buckets
  statement {
    sid = "BucketItemAccess"

    actions = local.s3_permissions

    resources = [for i in aws_s3_bucket.team_bucket : "arn:aws:s3:::${i.id}/*"]
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "team_role_s3_policy_attachment" {
  role = aws_iam_role.team_role.name
  policy_arn = aws_iam_policy.team_s3_access.arn
}

# Get the current account information so it can be used to limit the role usage by AWS Service
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_trust_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    # Allow ec2 compute services to assume the role. This could be better scoped with either more
    # parameters or better understanding of intended usage of the role
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}