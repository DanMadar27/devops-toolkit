# Share App

This folder contain scripts for sharing the app with on-premises environments.
It works with the `linux-instance-config` folder configuration.

## Pre Requisites:

- Docker compose installed on VM.

## Getting Started

- Connect to EC2 using SSM 

- Run the export script:
```bash
bash ~/infrastructure/share-app/export.sh <version> <s3-bucket> [--presign]
# e.g.
bash ~/infrastructure/share-app/export.sh 1.2.3 my-project-bucket
bash ~/infrastructure/share-app/export.sh 1.2.3 my-project-bucket --presign
```

The script will:
1. Export all Docker images to `project-<version>/project-images.tar.gz`
2. Copy ` (excluding `.env`), replacing `docker-compose.override.yml` with the one from `share-app/`
3. Compress everything into `project-<version>.tar.gz` and upload to S3
4. *(With `--presign`)* Print a presigned URL valid for 7 days