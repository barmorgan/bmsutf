# Repository Description
This repository is intended to allow teams to manage their own AWS resources,
isolating configs and terraform state by team. An s3 module is provided for secure
creation of s3 buckets and permissions around them, including an AWS Role.

# Bootstrapping a New Team
To bootstrap a new team:
1. Identify a team name. It must be all lower case, contain only letters, numbers,
   and hyphens, and match the regex `[a-z0-9][a-z0-9-]{1,}[a-z0-9]`
2. Branch the repository from the main branch into a branch named `teams/<team_name>`
3. In the team's branch, create a new directory under the `teams` directory named
   `teams/<team_name>`. Populate the directory with a copy of the files under
   `teams/_template` and modify as needed. Be sure to follow the rules in the
   README file at `teams/_template/README`.
4. Commit everything to the branch and push
5. The resources will be automatically previsioned. Additionally, viewing the
   action's Job Summary in GitHub will show any configured output values from
   terraform

# Offboarding a Team
To offboard a team and cleanup all its resources, add a marker file named `DESTROY`
to the team's directory in their branch, check-in, and push. This will trigger
`terraform destroy` rather than `terraform apply` and attempt to destroy all
resources. It is important to note that things like deletion protection may prevent
resources from being deleted, so it is not safe to assume that the automated
destroy will work on the first run. If problems are encountered, check the logs
and determine what changes need to be made to the configured resources, make those
changes, remove the `DESTROY` file to apply them if necessary, then re-add the
`DESTROY` file and try again.

Once the destroy build completes successfully, it is safe to delete the
`teams/<team_name>` branch.

# Technical Details
## Terraform State
Terraform state is stored in a dedicated s3 bucket. Terraform provides the ability
to use s3 as a storage backend out-of-the-box, which is what is being used. States
are partitioned in the bucket by prefixes matching the team name for clear symmetry
between git branches and state storage.

Consideration was made to using terraform workspaces to handle different users,
but ultimately that complicated the rest of the implementation: workspaces do
indeed store each state separately, but it ties them more closely together. A
solution using workspace would certainly be feasible, but it did not clearly
offer many benefits over individual states manged independently while adding
questions about coupling between team's states.

For end-user convenience, the backend configuration is separated out into a different
file that the build process adds at runtime. This means there is one less
thing the end-user needs to worry about being configured correctly within their
own team's directory, and it allows them to run `terraform init` locally to verify
configurations, run plan-only test cases, etc.

## Branch Management
There are two clear possibilities when looking at managing different terraform configs
within git: one branch with different directories for each config, or different branches
for each config. This implementation goes with the latter strategy for several reasons.

First, there is less likelihood of accidentally modifying the wrong teams config file,
because the user is specifically in their own team's branch, and they should only ever
need to work out of that branch. Additionally, because the directories are named 
differently for each team, if a merge were to take place, there is no possibility 
of corrupting one team's resources with another's.

The second benefit to branch-per-team is that it allows for rolling out changes to
the module incrementally by having module changes start in the main branch, and then
be merged up to each team's branch when they are ready to adopt those changes. If
there is a need to mass-apply the changes to multiple environments, it would be a 
simple exercise to script merging the main branch into all branches that begin with 
`teams/`. If the module was moved to its own repository, this benefit would be
nullified as the consumer of the module would be able to specify a tag in
the module source declaration.

And thirdly, it makes the build process easier to manage because a given commit
only ever affects one branch, making a build only have to deal with changes to
one team's environment at a time. The alternative here would be to support matrix
jobs, which is certainly feasible, but a more complicated solution.

## Offboarding Process
A marker file is used to determine that a given team's resources should be destroyed.
Thought was given to simply triggering destroy on branch deletion, but there are
too many cases where resources may not be cleaned up correctly on first run (such
as s3 buckets with files, ec2 instances with deletion protection, etc.), and
if the branch is already deleted it becomes much harder to make the needed changes
and re-attempt the destroy. Therefore, the branch should be kept until all resources
have been cleaned up (which can be determined by the build succeeding with the
`DESTROY` file present), after which it can be safely deleted.

Destroying all the resources does not cleanup the state file (it just empties it).
The process therefore concludes (once all resouces have been successfully destroyed)
by deleting the state file from s3 manually.

## Security
### Security of the Build
The build is currently secured with AWS API keys stored as secrets. The API keys
are tied to a user that has limited permissions, only scoped to be able to manage
S3 and IAM resources. This is not really ideal, but was simple to setup for this
demo. A better solution would be to utilize OpenID Connect (OIDC) to allow GitHub
to assume an IAM Role in the AWS Account. Further auditing of exactly what permissions
GitHub automations need would also be appropriate.

State is stored independently for each team in a common s3 bucket; the teams do
not have direct access to the s3 bucket storing state. Modification of the build
scripts could allow a team to access a different team's state, as a common
role is used for all automated operations in GitHub reguardless of team. Securing
this more completely would require changes to the overall architecture of the
build, repository, and AWS structure. 
See [Larger Picture Considerations](#larger-picture-considerations).

# Questions and Corner Cases
- How do multiple quick commits to the same branch get handled in terms of 
  automated builds?

# Potential Future Improvements

- Move module to its own repository
  - Run `terraform validate` on module as pre-commit check
  - Dedicate a different aws environment to running tests that create resources
  - Move testing script to run on pull request to master rather than push to master
  - Further lock down AWS permissions provided to GitHub to only support the
    bare minimum of permissions needed; currently it is limited to access to the
    services needed, but not the specific permissions
- Change auth to AWS from GitHub to use OpenID Connect (OIDC) rather than 
  using credentials stored as secrets
- Require a manual step in the build process to verify the terraform plan
  before applying planned changes
- Supply a `.terraform.lock.hcl` file in the team template and/or recommend
  the end-user generate one and include it in their committed code
- Audit `.gitignore` to make sure terraform binary resources aren't included in
  team's commits (or the module commits)
- Adjust AWS permissions supplied to GitHub to account for defining resource
  beyond the scope of the s3 module (limited to what end-users should be permitted
  to utilize)
- Run `terraform validate` on any `teams` sub-directory that has changes as
  pre-commit check
- Support automated running of test cases defined by team`s resource configurations 
- Rather than having the s3 module create an IAM Role, instead have it create
  an IAM Policy that can be attached to any Role that needs access to the buckets. If
  required, a separate module that creates IAM Roles could be created with parameters
  allowing for roles intended to be assumed by humans, roles intended to be used
  by other AWS services, etc.; it would also allow the s3 policy, as well as other
  policies, to be supplied and associated with the role. Policies with multiple
  levels of access could be generated to allow teams to follow best practices around
  least-permissions whenever possible (ie. service `x` only ever reads files from
  a bucket, it should use a read-only policy).

# Larger Picture Considerations

- Consider moving to org-per-team. This would simplify billing management and 
  further isolate team's resources.
- If using org-per-team, abstract team onboarding one level higher and have
  automation that creates new a new org, along with access roles and permissions
  that only allow for access to resources within the new org. The new role(s) would
  be used for configuring git access to the org. 
- Org-per-team would allow using Service Control Policies to better take advantage
  of AWS best practices around limiting permission scopes
- Assuming usage of some sort of SSO, created orgs can have user role assumption 
  tied to existing SSO groups to ensure single-point-of-truth for access permissions
- Initial org initialization automation can fork the base environment repo that
  acts as a template for each team, configure that fork to use the newly
  created IAM Roles for GitHub, and limit GitHub access to existing SSO groups.
  This creates a significantly higher level of isololation and security because
  it specifically prevents a user from making changes to a different team's
  environment, even if that user has malicious intent. The current implementation
  does its best to limit cross-resource changes from accidental causes, but does
  not have the ability to prevent malicious changes cross-team. While everyone
  hopes there is never a malicious actor within one's own organization, it can
  happen; additionally, preventing against malicious intent limits the scope
  of damages should an end-user's credentials be compromised. Overall, prevention
  of malicious changes cross-team is a better implementation of least-priviledge
  best practices.
- For Org-per-team, state could either be stored in a bucket in the team's org,
  or stored centrally with the GitHub role for each team being limited to only
  access their own state sub-directory in the common s3 bucket, thereby preventing
  any access to other team's state files, even through modifications of the
  build scripts.
- If moving to org-per-team, consider doing OU (Organizational Unit) per team,
  and allowing both a prod and a dev environment for each team. This assumes
  that the team controls their own prod environment in the first place. This
  could be extended to include staging environments, etc based on usage patterns.
- Org-per-team does introduce some potential limits issues, specifically around
  the number of accounts that can be associated with an org. The default limit
  appears to be 10 accounts, but it can be increased up to 50,000, which should
  more than cover 2x300 + Management Org + orgs for security & auditing + other
  centralized orgs. Some centralized services (such as Security Hub) have lower
  limits, but they still appear to be around 10,000, so still within expected usage.
- Org-per-team allows security findings from Security Hub, etc. to be more clearly
  associated with one teams resources. Automation could be implemented to assign
  newly created tickets to a given team. It may be possible to do something
  similar based on tagging, but tagging is harder to enforce and harder to
  automatically trace between resources in a shared environment.
- Org-per-team introduces some complications in cross-account resource access
  in cases where a team needs to share resources with another team. These issue
  should be able to be mitigated by providing modules that implement best
  practices. The additional requirements of explicitly sharing resources
  cross-account can be seen as a set of checks and balances because it requires
  that both teams work together to share resources; within a single org, one team
  could gain access to another teams resources without making any changes to the
  other team's code just by creating new IAM Policies that reference the teams
  resources. For some types of resources, a resource-based policy can be used,
  which would not require any operational changes to code, etc. For other types
  of resources, permissions would have to be grated via a properly configured role
  which may require changes to application code, etc. Other possibilities exist
  for accessing cross-account resources including networking options like VPC
  peering, AWS Private Link endpoint services, VPN, etc.
- There are options that could be considered around output sharing between states
  with limits on who can see what. It would be possible with Terraform Cloud,
  for example, and may be possible otherwise. Certainly something like a common
  datastore could be published to at the team's discretion; if the data store
  supports different access permissions, the publishing team could control
  who would be able to access those values. Sharing values in some way would
  limit the need for teams to explicitly, manually pass values around between
  themselves and would reduce the likelihood of a team not getting an updated
  value when something changes. The harness around sharing and consuming shared 
  values would ideally be provided by the platform team.
- An extension of the value sharing exercise would be notifying consumers of
  a shared value when it is changed, and possibly automatically re-running
  terraform for environments that depend on a changing value. This could possibly
  be implemented by the module that allows consuming shared values, having the
  module register itself against the central shared values store, and implementing
  build hooks that can be called by the central store whenever a value changes.