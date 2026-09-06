# this file must exist with this name under the team-specific directory

# name of the team. must be at least 3 chars, all lower-case or numbers or hyphens (match regex `[a-z0-9][a-z0-9-]{1,}[a-z0-9]`)
team_name=""

# list of buckets to create. bucket names must be at least 3 chars, all lower-case or numbers or hyphens (match regex `[a-z0-9][a-z0-9-]{1,}[a-z0-9]`)
# `public` can be [true, false] and `false` should be used unless there is an explicit reason to make the bucket have public read access
buckets=[{name="", public=false}]

# list of names of buckets that you want to destroy. values in this list do NOT immediately destroy the bucket, but allow it to be
# removed from the `buckets` list on subsequent check-ins, at which time the bucket will be deleted. There is no harm in
# leaving non-applicable values in this list
buckets_to_destroy=[""]