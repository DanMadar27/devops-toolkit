#!/bin/bash

# Script to replicate an image from an S3 bucket (tar image file) to an ECR repository

set -e

S3_BUCKET="$1"        # Example: s3://my-bucket/path/to/image.tar
DST_ECR="$2"         # Example: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:latest
SRC_ROLE="$3"         # IAM role ARN for S3 access
DST_ROLE="$4"         # IAM role ARN for ECR access

# Extract filename from S3 path
IMAGE_TAR=$(basename "$S3_BUCKET")

# Store original EC2 instance credentials
ORIGINAL_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ORIGINAL_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ORIGINAL_AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN

assume_role() {
    ROLE_ARN=$1
    CREDS=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "ECRMigrationSession")
    export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r .Credentials.AccessKeyId)
    export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r .Credentials.SecretAccessKey)
    export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r .Credentials.SessionToken)

    echo "Assumed role: $ROLE_ARN"
    aws sts get-caller-identity  # Debugging
}

restore_ec2_role() {
    export AWS_ACCESS_KEY_ID=$ORIGINAL_AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY=$ORIGINAL_AWS_SECRET_ACCESS_KEY
    export AWS_SESSION_TOKEN=$ORIGINAL_AWS_SESSION_TOKEN

    echo "Restored EC2 instance profile credentials"
    aws sts get-caller-identity  # Debugging
}

echo "Getting credentials for S3"
assume_role "$SRC_ROLE"

echo "Downloading image from S3: $S3_BUCKET"
aws s3 cp "$S3_BUCKET" "/tmp/$IMAGE_TAR"

echo "Restoring EC2 credentials before assuming destination role"
restore_ec2_role

echo "Loading image into Docker"
IMAGE_ID=$(sudo docker load -i "/tmp/$IMAGE_TAR" | awk '{print $3}')  # Extract image ID
echo "Loaded image: $IMAGE_ID"

echo "Tagging image for ECR: $DST_ECR"
sudo -E docker tag "$IMAGE_ID" "$DST_ECR" # using -E to preserve AWS environment variables

echo "Assuming role for ECR push"
assume_role "$DST_ROLE"

echo "Logging into ECR"
aws ecr get-login-password --region $(echo "$DST_ECR" | cut -d'.' -f4) | docker login --username AWS --password-stdin "$DST_ECR"

echo "Pushing image to ECR"
sudo -E docker push "$DST_ECR" # using -E to preserve AWS environment variables

echo "Cleanup: Removing local tar file"
rm -f "/tmp/$IMAGE_TAR"

echo "Deleting local Docker image"
sudo -E docker rmi "$DST_ECR"

echo "Local Docker images deleted"
echo "Image successfully pushed to ECR: $DST_ECR"
