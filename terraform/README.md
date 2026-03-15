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
- [HCP Terraform Workspace](https://app.terraform.io/) 

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
  - AWS S3
  - GCS (Google Cloud Storage)
  - Azure Storage (Blob)
  - Consul
  - PostgreSQL and other supported backends
- **Third‑party orchestration**: CI/CD systems (GitHub Actions, GitLab CI, Jenkins, etc.) can run Terraform commands using any of the remote backends above, giving you centralized pipelines plus remote state, while still using the standard Terraform CLI commands.

## The GitOps Lifecycle with HCP Terraform

### 1. Workspace Isolation

* Create a dedicated workspace in your HCP organization (e.g., `prod-infrastructure` or `staging-app-db`).
* Map this workspace to a specific **GitHub Repository** and a specific **Branch** (usually `main` or `master`).

### 2. VCS Integration (The "Webhook")

* Establish the connection between HCP and GitHub.
* HCP Terraform automatically installs a **webhook** that listens for two events: **Pull Requests** and **Merges**.

### 3. Safety Gate: Manual Apply

* Set the "Apply Method" to **Manual Apply**.
* This ensures that even if code reaches the `main` branch, a human must review the final plan before the infrastructure actually changes.

### 4. The Pull Request (The "Plan" Phase)

* A DevOps member pushes a new branch and opens a **Pull Request**.
* HCP Terraform triggers a **Speculative Plan**.
* The results (Plan: X to add, Y to change, Z to destroy) appear directly inside the GitHub PR as a status check.
* **Team Lead Role:** Reviews the plan output in the PR or in HCP workspace. If it’s risky (e.g., deleting a database), they request changes or decline the PR.

Note: About viewing plan output:
1. Option 1: The "Standard" Status Check (Built-in)
  Look at the bottom of the PR for the Checks section.
  Click "Details" next to the Terraform run.
  This will link you directly to the HCP Terraform UI to see the plan.
  Note: This keeps the PR "clean" but requires the reviewer to leave GitHub to see the details.

2. Option 2: The "Pro" Way (GitHub Actions + tf-summarize)
  Some DevOps teams use a small GitHub Action to "fetch" the plan from HCP and post it as a comment.

### 5. The Merge (The "Apply" Phase)

* Once the Team Lead approves and **Merges the PR** into `main`, HCP Terraform triggers a **Confirmed Run**.
* Because the code is now in the "source of truth" branch, the plan is locked.
* The Team Lead (or authorized member) goes to the HCP UI to click **"Confirm & Apply"**.

### 6. State Management

* HCP Terraform automatically **locks the state** during these runs.
* This prevents "State Contention," where two people try to update the same resource simultaneously.

---

### Industry Comparison: VCS vs. CLI

| Feature | **VCS-Driven (Standard)** | **CLI-Driven (Local)** |
| --- | --- | --- |
| **Execution** | Runs on Hashicorp's infrastructure. | Runs on your local machine. |
| **Visibility** | Team can see the plan in the PR. | Only the runner sees the plan. |
| **Security** | Secrets stay in HCP Terraform. | Secrets must be on your local machine. |
| **History** | Full audit log of who applied what. | Harder to track local history. |

**Would you like me to show you how to set up "Variable Sets" so you can share your cloud credentials across multiple workspaces?**