locals {
  company_namespace = "bmsutf" # used to prefix all s3 buckets created
  bucket_names = {for i in var.buckets : i.name => i.public}
}

# Create an s3 bucket for each bucket name configured in the supplied variables
resource "aws_s3_bucket" "team_bucket" {
  for_each = local.bucket_names

  bucket = "${local.company_namespace}--${var.team_name}--${each.key}"

  # allow for deleting the bucket with all contents if the bucket is explicitly listed for destroy or if the whole environment is flagged for destroy
  force_destroy = var.allow_destroy || contains(var.buckets_to_destroy, each.key)

  lifecycle {
    # Changes to team name or company namespace shouldn't try to replace the bucket.
    # Because the resource is for_each based on supplied bucket name, changes to the list of configured buckets will result
    # in attempting to delete the old bucket and create a new one.
    ignore_changes = [bucket]
  }

  tags = {
    Teams = var.team_name
    ManagedModule = "s3"
  }
}

# If this is not a public bucket, block all public access; if this is a public bucket, disable public blocks.
# Applied to each configured bucket
resource "aws_s3_bucket_public_access_block" "team_bucket_public_access_block" {
  for_each = local.bucket_names

  bucket = aws_s3_bucket.team_bucket[each.key].id

  # sets all restrictions for the bucket if the bucket is NOT configured to be public
  block_public_acls = !each.value
  block_public_policy = !each.value
  ignore_public_acls = !each.value
  restrict_public_buckets = !each.value
}

# Bucket policy applied for each bucket created. All buckets limit access to the api to ssl only.
# Public buckets additionally allow public read.
resource "aws_s3_bucket_policy" "s3_policy_ssl_only" {
  depends_on = [aws_s3_bucket_public_access_block.team_bucket_public_access_block] # make sure the policy block is in place before attempting to add a bucket policy

  for_each = local.bucket_names

  bucket = aws_s3_bucket.team_bucket[each.key].id

  # if this is a public bucket, use the bucket policy that allows global read in addition to requiring SSL
  # otherwise, just require SSL
  policy = each.value == true ? data.aws_iam_policy_document.allow_global_read_doc[each.key].json : data.aws_iam_policy_document.s3_policy_ssl_only_doc[each.key].json
}

# Bucket policy to limit api operations against s3 to ssl only
data "aws_iam_policy_document" "s3_policy_ssl_only_doc" {
  for_each = local.bucket_names

  statement {
    sid = "SSLOnly"

    actions = ["s3:*"]

    effect = "Deny"

    resources = ["${aws_s3_bucket.team_bucket[each.key].arn}", "${aws_s3_bucket.team_bucket[each.key].arn}/*"]

    principals {
      type = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      values = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

# Bucket policy allowing public read to all items it a bucket; only applied to public buckets
data "aws_iam_policy_document" "allow_global_read_doc" {
  for_each = {for k, v in local.bucket_names : k => v if v == true}

  source_policy_documents = [data.aws_iam_policy_document.s3_policy_ssl_only_doc[each.key].json]

  statement {
    sid = "PublicRead"

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.team_bucket[each.key].arn}/*"]

    principals {
      type = "*"
      identifiers = ["*"]
    }
  }
}