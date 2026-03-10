# AWS Terraform

Links:

- [Hashicorp tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-create)
- [Hashicorp registry](https://registry.terraform.io)

## AWS CLI

Go to your own IAM user and manage access keys:
https://console.aws.amazon.com/iam/home#/users/${your-username}

Switch profile in aws cli

```bash
# View your aws profiles
aws configure list-profiles

# Set profile in current session
export AWS_PROFILE=dev

# Verify current profile
aws sts get-caller-identity
```

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
```

Apply infrastructure changes:

```bash
terraform apply
```

List resources and data sources:

```bash
terraform state list
```

Print out entire state:

```bash
terraform show
```

## Infrastructure State

By default, Terraform creates your state file locally. Storing your state remotely Using HCP Terraform will let you collaborate with your team more easily and keep your state file secure.
