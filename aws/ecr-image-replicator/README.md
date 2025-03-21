# ECR Image Replicator

Scripts to replicate Docker images between AWS ECR repositories and from S3 to ECR.

## Prerequisites

- AWS CLI installed and configured
- Docker installed
- Appropriate IAM roles with necessary permissions
- sudo privileges on the execution machine

## Scripts

### 1. ECR to ECR Replication

[`replicate_ecr_image.sh`](replicate_ecr_image.sh) copies an image from one ECR repository to another.

```bash
./replicate_ecr_image.sh SOURCE_ECR DESTINATION_ECR SOURCE_ROLE DESTINATION_ROLE
```

Example:
```bash
./replicate_ecr_image.sh \
    "account-id.dkr.ecr.eu-central-1.amazonaws.com/dev-backend:latest" \
    "account-id.dkr.ecr.eu-central-1.amazonaws.com/prod-backend:latest" \
    "arn:aws:iam::account-id:role/PullImages" \
    "arn:aws:iam::account-id:role/CustomEcrRole"
```

### 2. S3 to ECR Replication

[`replicate_s3_image.sh`](replicate_s3_image.sh) copies a Docker image (tar file) from S3 to an ECR repository.

```bash
./replicate_s3_image.sh S3_BUCKET DESTINATION_ECR SOURCE_ROLE DESTINATION_ROLE
```

Example:
```bash
./replicate_s3_image.sh \
    "s3://my-bucket/images/react-frontend.tar" \
    "account-id.dkr.ecr.eu-central-1.amazonaws.com/react-frontend:latest" \
    "arn:aws:iam::account-id:role/PullImages" \
    "arn:aws:iam::account-id:role/CustomEcrRole"
```

## Required IAM Permissions

### Source Role Permissions
- For ECR source:
  - `ecr:GetDownloadUrlForLayer`
  - `ecr:BatchGetImage`
  - `ecr:BatchCheckLayerAvailability`
  - `ecr:GetAuthorizationToken`
- For S3 source:
  - `s3:GetObject`
  - `s3:ListBucket`

### Destination Role Permissions
- `ecr:PutImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetAuthorizationToken`

Note: The `ecr:GetAuthorizationToken` permission must be granted for `*` resources as it operates at the registry level, not the repository level.

## Test Scripts

Two test scripts are provided:
- [`test_replicate_ecr_image.sh`](test_replicate_ecr_image.sh)
- [`test_replicate_s3_image.sh`](test_replicate_s3_image.sh)

These demonstrate usage with example values.

## Notes

- Scripts require sudo access for Docker commands
- Uses `-E` flag with sudo to preserve AWS environment variables
- Automatically cleans up local images after replication
- Handles AWS credential switching between source and destination roles