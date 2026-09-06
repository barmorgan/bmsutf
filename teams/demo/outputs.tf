output "role_arn" {
  value = module.s3_buckets.role_arn
  description = "ARN of the role having access to all s3 buckets managed by this terraform module"
}

output "bucket_names" {
  value = module.s3_buckets.bucket_names
  description = "Full names of s3 buckets managed by this terraform module"
}

output "public_bucket_endpoints" {
  value = module.s3_buckets.public_bucket_endpoints
  description = "Domain endpoints for public buckets"
}