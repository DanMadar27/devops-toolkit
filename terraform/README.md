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
