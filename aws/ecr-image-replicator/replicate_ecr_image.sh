#!/bin/bash

# Script to replicate an ECR image from one ECR repository to another

set -e

# Store original EC2 instance credentials
ORIGINAL_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ORIGINAL_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ORIGINAL_AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN

SRC_ECR="$1"
DST_ECR="$2"
SRC_ROLE="$3"
DST_ROLE="$4"

assume_role() {
    ROLE_ARN=$1
    CREDS=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "ECRMigrationSession")
    export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r .Credentials.AccessKeyId)
    export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r .Credentials.SecretAccessKey)
    export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r .Credentials.SessionToken)

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

echo "Getting credentials"
assume_role "$SRC_ROLE"
aws ecr get-login-password --region $(echo "$SRC_ECR" | cut -d'.' -f4) | docker login --username AWS --password-stdin "$SRC_ECR"
echo "Credentials fetched successfully"

echo "Pulling image from $SRC_ECR"
sudo -E docker pull "$SRC_ECR" # using -E to preserve AWS environment variables
sudo -E docker tag "$SRC_ECR" "$DST_ECR" # using -E to preserve AWS environment variables

echo "Restoring EC2 credentials before assuming destination role"
restore_ec2_role

echo "Pushing image to $DST_ECR"
assume_role "$DST_ROLE"
aws ecr get-login-password --region $(echo "$DST_ECR" | cut -d'.' -f4) | docker login --username AWS --password-stdin "$DST_ECR"
sudo -E docker push "$DST_ECR"

echo "Deleting local Docker image"
sudo -E docker rmi "$SRC_ECR"
sudo -E docker rmi "$DST_ECR"
echo "Local Docker images deleted"

echo "Replication completed successfully!"
