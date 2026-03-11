# AWS Terraform

Links:

- [Hashicorp tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-create)
- [Hashicorp registry](https://registry.terraform.io/providers/hashicorp/aws/latest)

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
