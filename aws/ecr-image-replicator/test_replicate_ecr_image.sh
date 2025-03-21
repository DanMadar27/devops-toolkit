#!/bin/bash

set -e

SRC_ECR="account-id.dkr.ecr.eu-central-1.amazonaws.com/dev-backend:latest"
DST_ECR="account-id.dkr.ecr.eu-central-1.amazonaws.com/prod-backend:latest"
SRC_ROLE="arn:aws:iam::account-id:role/PullImages"
DST_ROLE="arn:aws:iam::account-id:role/CustomEcrRole"

bash replicate_ecr_image.sh "$SRC_ECR" "$DST_ECR" "$SRC_ROLE" "$DST_ROLE"
