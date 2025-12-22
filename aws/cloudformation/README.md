# AWS CloudFormation

## What is CloudFormation?

AWS CloudFormation is an Infrastructure as Code (IaC) service that allows you to define and provision AWS infrastructure using YAML or JSON templates. Instead of manually creating resources through the AWS Console, you define everything in code, making your infrastructure reproducible, version-controlled, and automated.

### Key Benefits
- **Reproducibility**: Deploy identical infrastructure across multiple environments
- **Version Control**: Track infrastructure changes over time using Git
- **Automation**: Automate infrastructure provisioning and updates
- **Consistency**: Eliminate configuration drift and human errors
- **Rollback**: Automatically rollback failed deployments

## How to Use

### Prerequisites
- AWS CLI installed and configured
- Appropriate AWS credentials with CloudFormation permissions
- Edit `parameters.json` with your desired values

### Create Stack

To launch a new CloudFormation stack:

```bash
aws cloudformation create-stack \
  --stack-name my-app-stack \
  --template-body file://cloudFormationTemplate.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_IAM
```

### Update Stack

To update an existing CloudFormation stack:

```bash
aws cloudformation update-stack \
  --stack-name my-app-stack \
  --template-body file://cloudFormationTemplate.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_IAM
```

### Additional Useful Commands

Check stack status:
```bash
aws cloudformation describe-stacks --stack-name my-app-stack
```

Delete stack:
```bash
aws cloudformation delete-stack --stack-name my-app-stack
```

List all stacks:
```bash
aws cloudformation list-stacks
```

## Template Overview

This template creates:
- **VPC**: Virtual Private Cloud with customizable CIDR block
- **Internet Gateway**: Enables internet access for the VPC
- **Public Subnets**: Two subnets across different availability zones
- **Route Tables**: Routing configuration for public internet access
- **Security Group**: Controls inbound/outbound traffic for web servers
- **S3 Bucket**: Storage with encryption and security best practices

## Parameters

Modify `parameters.json` to customize your deployment:
- `EnvironmentName`: Environment type (dev, staging, prod)
- `VpcCIDR`: IP range for your VPC
- `PublicSubnet1CIDR`: IP range for first public subnet
- `PublicSubnet2CIDR`: IP range for second public subnet
- `InstanceType`: EC2 instance size

## Outputs

The stack exports these values for use by other stacks:
- VPC ID
- Subnet IDs
- Security Group ID
- S3 Bucket Name
