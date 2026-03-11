# Terraform

Links:

- [Hashicorp tutorial](https://developer.hashicorp.com/terraform/tutorials/)
- [Hashicorp registry](https://registry.terraform.io)


## Terraform CLI

Format configuration files:

```bash
terraform fmt
```

Initialize workspace with dependencies:

```bash
terraform init
```

Validate configuration:

```bash
terraform validate
```

Plan and review infrastructure changes:

```bash
terraform plan

# Or with variables
terraform plan -var instance_type=t2.large
```

Apply infrastructure changes:

```bash
terraform apply

# Or with variables
terraform apply -var instance_type=t2.large
```

Alternatively, create a `terraform.tfvars` file (excluded from git) to avoid passing vars on every command:

```hcl
variable_name    = "variable value"
```

List resources and data sources:

```bash
terraform state list
```

Print out entire state:

```bash
terraform show
```

Review output values:

```bash
terraform output
```

Destroy workspace infrastructure:

```bash
terraform destroy
```

## Infrastructure State

By default, Terraform creates your state file locally. Storing your state remotely Using HCP Terraform will let you collaborate with your team more easily and keep your state file secure.

## Folder Structure

- `terraform.tf`: Define terraform configuration such as the cloud providers we will use.

- `main.tf`: Main entry point for resources we create.

- `variables.tf`: Define variables for the resources we created. This is useful to make the configuration more flexible and reusable.

- `outputs.tf`: Define outputs for the resources we created. This is useful to share the values with other services or to use in other scripts. For example, we can use the instance hostname in other services to connect to the instance.

## Remote Control

Links:

- [AWS With HCP Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-hcp-terraform)

The Standard Workflow:

1. **Code:** A developer writes HCL code on a new Git branch.

2. **Commit:** They push code to GitHub/GitLab.

3. **Plan:** A CI/CD pipeline (like GitHub Actions) automatically runs terraform plan and posts the output as a comment on the Pull Request.

4. **Review**: A senior engineer reviews the plan.

5. **Merge & Apply**: Once merged to the main branch, the pipeline runs terraform apply automatically using the Remote Backend.

### HCP Terraform (Terraform Cloud)

- **Use the `cloud` block**: Configure Terraform to use HCP Terraform (Terraform Cloud) so plans/applies run remotely and state is stored in the cloud:

```hcl
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      name = "my-workspace"
    }
  }
}
```

- **Authenticate with `terraform login`**: Run `terraform login` once locally to generate an API token and store it in `~/.terraform.d/credentials.tfrc.json`. After that, `terraform init`, `plan`, and `apply` will use HCP Terraform for remote runs and remote state.

### Other Remote State / Remote Run Options

- **Terraform Enterprise**: Self‑hosted version of Terraform Cloud for organizations that need to run Terraform in their own environment.
- **Cloud storage backends** (remote state only, local execution):
  - AWS S3 + DynamoDB locking
  - GCS (Google Cloud Storage)
  - Azure Storage (Blob)
  - Consul
  - PostgreSQL and other supported backends
- **Third‑party orchestration**: CI/CD systems (GitHub Actions, GitLab CI, Jenkins, etc.) can run Terraform commands using any of the remote backends above, giving you centralized pipelines plus remote state, while still using the standard Terraform CLI commands.