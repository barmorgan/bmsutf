# Module Description
This module provides an abstraction to create s3 buckets and an IAM Role to
access them. Buckets may be public or private. Variables and Outputs are defined
below.

**Variables**

| Variable           | Description                                                                                                                                            | Required | Default | Example                                                                    |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|----------------------------------------------------------------------------|
| team_name          | The name of the team. Must match regex `[a-z0-9][a-z0-9-]{1,}[a-z0-9]`                                                                                 | T        | n/a     | `"my-new-team"`                                                            |
| buckets            | A list of buckets to be created. Each bucket name must match regex `[a-z0-9][a-z0-9-]{1,}[a-z0-9]`. Each bucket may be flagged to be public if needed. | T        | n/a     | `[{name="bucket-1", public=false}, {name="bucket-2-public", public=true}]` |
| buckets_to_destroy | A list of bucket names to make available to destroy. See [Removing an Already Existing Bucket](#removing-an-already-existing-bucket).                  | F        | `[]`    | `["bucket-2-public"]`                                                      |
| allow_destroy      | Allows for all resources in the module to be destroyed. See [Removing the Module Completely](#removing-the-module-completely).                         | F        | `false` | `false`                                                                    |

**Outputs**

| Output                  | Description                                                                                                                           | Example                                                                                                                  |
|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| role_arn                | The ARN of the role that was created with permissions to the buckets                                                                  |                                                                                                                          |
| bucket_names            | The full names of the buckets created. Presented in a map of the bucket name provided in `buckets` to the full name                   | `{ "bucket-1": "company-name--my-new-team--bucket-1", "bucket-2-public": "company-name--my-new-team--bucket-2-public" }` |
| public_bucket_endpoints | The global domain endpoint for any public buckets created. Presented in a map of the bucet name provided in `buckets` to the endpoint | `{ "bucket-2-public": "company-name--my-new-team--bucket-2-public.s3.us-east-2.amazonaws.com" }`                         |

# Removing an Already Existing Bucket
This is a two step process due to the need to clear out all objects from the s3
bucket. To delete a bucket, add the bucket name to the list variable 
`buckets_to_destroy` and then apply. After it has applied successfully, you can 
remove it from the `buckets` list and apply again, at which point the bucket and 
all contents will be deleted permanently.

# Removing the Module Completely
This is a two step process due to the need to clear out all objects from the s3
buckets. First, supply the `allow_destroy=true` property to the module and
apply the terraform changes. Then you may remove the module and the 
resources--including the buckets and all objects stored in them--will be deleted
on the next terraform apply (or terraform destroy).

# Misc Details

- All resources that are created in AWS are tagged with the name of the team
  who has requested them. This allows for easy tracking of who is responsible for
  what and additionally allows for usage and billing reporting using standard
  AWS tools. (`Team=<team_name>`)
- All resources that are created in AWS are tagged with the name of the module
  to easily track created resources back to the source code. (`ManagedModule=s3`)

## Security
### Security of the Build
The build is currently secured with AWS API keys stored as secrets. The API keys
are tied to a user that has limited permissions, only scoped to be able to manage
S3 and IAM resources. This is not really ideal, but was simple to setup for this
demo. A better solution would be to utilize OpenID Connect (OIDC) to allow GitHub
to assume an IAM Role in the AWS Account. Further auditing of exactly what permissions
GitHub automations need would also be appropriate.

There is only one AWS account being used for testing the module and team 
environments, which is not best practice, but was the simplest solution for this
demo and does not impede functionality, only provides lower security guarantees. 

### Security of the Resources
- Configuration attempts to make clear that public buckets are public and should
  not be used by default. 
- Bucket policies ensure all s3 access is via ssl
- The generated role is strictly limited in scope (what scope is needed is an
  open question, but it is currently limited to only ec2 service access)
- The generated role does not allow access to anything beyond basic read/write
  access to resources in the buckets. The consumer of the role does not have
  any ability to modify the bucket configuration itself, delete the bucket,
  or create any other buckets; they also do not have access to resources in
  any buckets besides those that are created by this module.

# Questions and Corner Cases

- How are the buckets going to be accessed? There is an IAM Role, but
  it is unclear how it should be scoped in terms of who/what can assume it.
- What operations are needed against the created s3 buckets? Are versioning,
  multipart uploads, etc. needed?

# Potential Future Improvements

- Move module to its own repository
- Consider eschewing public s3 buckets all together in favor of CloudFront 
  distributions
- Change auth to AWS from GitHub to use OpenID Connect (OIDC) rather than
  using credentials stored as secrets
- Run `terraform validate` on module as pre-commit check
- Dedicate a different aws environment to running tests that create resources
- Move testing script to run on pull request to master rather than push to master