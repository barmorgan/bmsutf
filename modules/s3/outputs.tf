output "role_arn" {
  value = aws_iam_role.team_role.arn
  description = "ARN of the role having access to all s3 buckets managed by this terraform module"
}

output "bucket_names" {
  value = {for k, v in local.bucket_names : k => aws_s3_bucket.team_bucket[k].bucket}
  description = "Full names of s3 buckets managed by this terraform module; map of provided bucket name to full bucket name."
}

output "public_bucket_endpoints" {
  value = {for k,v in local.bucket_names : k => aws_s3_bucket.team_bucket[k].bucket_domain_name if v == true}
  description = "Domain endpoints for public buckets; map of provided bucket name to endpoint"
}