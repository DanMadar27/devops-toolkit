#!/bin/bash

set -e

S3_BUCKET="s3://my-bucket/images/react-frontend.tar"
DST_ECR="account-id.dkr.ecr.eu-central-1.amazonaws.com/react-frontend:latest"
SRC_ROLE="arn:aws:iam::account-id:role/PullImages"
DST_ROLE="arn:aws:iam::account-id:role/CustomEcrRole"

bash replicate_s3_image.sh "$S3_BUCKET" "$DST_ECR" "$SRC_ROLE" "$DST_ROLE"

sudo docker rmi react-frontend:latest # for cleanup
