module "s3_buckets" {
  source = "../../modules/s3"

  team_name = var.team_name
  buckets = var.buckets
  buckets_to_destroy = var.buckets_to_destroy
  allow_destroy = var.allow_destroy
}