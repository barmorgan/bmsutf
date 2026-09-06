variable "team_name" {
  type = string
  description = "Alias for the name of the team. Must be unique to each team. Must be >= 3 chars; lowercase; only contain letters, numbers, and hyphen; must not start or end with a hyphen."

  validation {
    condition = can(regex("^[a-z0-9][a-z0-9-]{1,}[a-z0-9]$", var.team_name))
    error_message = "team_name must conform to regex ^[a-z0-9][a-z0-9-]{1,}[a-z0-9]$"
  }
}

variable "buckets" {
  type = list(object({
    name = string
    public = bool
  }))
  description = "List of buckets, supplying a name and visibility for each. Must be >= 3 chars; lowercase; only contain letters, numbers, and hyphen; must not start or end with a hyphen."

  validation {
    condition = length(var.buckets) >= 1
    error_message = "at least one bucket must be declared"
  }

  validation {
    condition = length(var.buckets) == length([for i in var.buckets : true if can(regex("^[a-z0-9][a-z0-9-]{1,}[a-z0-9]$", i.name))])
    error_message = "each bucket name must conform to regex ^[a-z0-9][a-z0-9-]{1,}[a-z0-9]$"
  }

  validation {
    condition = length(var.buckets) == length(distinct([for i in var.buckets : i.name]))
    error_message = "each bucket must have a unique name"
  }
}

variable "buckets_to_destroy" {
  type = list(string)
  # default = []
}

# this allows all objects in an s3 bucket to be deleted during deletion of a bucket
# this has to be set to true and applied successfully before a terraform destroy will clean up the bucket correctly
variable "allow_destroy" {
  type = bool
  # default = false
  description = "Allow recursive cleanup of all resources in s3 buckets. Should only be overridden during offboarding process."
}