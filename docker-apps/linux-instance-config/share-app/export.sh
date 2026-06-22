#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: $0 <version> <s3-bucket> <s3-path> [--presign]"
  echo "  e.g. $0 1.2.3 my-project-bucket exports/project"
  echo "       $0 1.2.3 my-project-bucket exports/project --presign"
  exit 1
}

[[ $# -lt 3 ]] && usage

VERSION="$1"
BUCKET="$2"
S3_PATH="$3"
PRESIGN=false
[[ "${4:-}" == "--presign" ]] && PRESIGN=true

[[ -z "$BUCKET" ]] && { echo "ERROR: empty S3 bucket" >&2; usage; }
[[ -z "$S3_PATH" || "$S3_PATH" == --* ]] && { echo "ERROR: invalid S3 path: '$S3_PATH'" >&2; usage; }
FOLDER="project-$VERSION"
ARCHIVE="project-$VERSION.tar.gz"
S3_KEY="$S3_PATH/$VERSION/$ARCHIVE"

trap 'rm -rf "$FOLDER" "$ARCHIVE"' EXIT

echo "==> Creating version folder: $FOLDER"
mkdir "$FOLDER"

echo "==> Exporting Docker images to $FOLDER/project-images.tar.gz"
docker save $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v '<none>') \
  | gzip > "$FOLDER/project-images.tar.gz"

echo "==> Copying linux-instance-config"
cp -r "$INFRA_DIR/linux-instance-config" "$FOLDER/"
rm -f "$FOLDER/linux-instance-config/.env"
rm -f "$FOLDER/linux-instance-config/docker-compose.override.yml"

echo "==> Copying docker-compose.override.yml from share-app"
cp "$SCRIPT_DIR/docker-compose.override.yml" "$FOLDER/linux-instance-config/docker-compose.override.yml"

echo "==> Compressing to $ARCHIVE"
tar -czf "$ARCHIVE" "$FOLDER/"
rm -rf "$FOLDER/"

echo "==> Uploading to s3://$BUCKET/$S3_KEY"
aws s3 cp "$ARCHIVE" "s3://$BUCKET/$S3_KEY" --no-progress
rm -f "$ARCHIVE"

if [[ "$PRESIGN" == true ]]; then
  echo "==> Generating presigned URL (expires in 7 days)"
  PRESIGNED_URL="$(aws s3 presign "s3://$BUCKET/$S3_KEY" --expires-in 604800)"
  echo "PRESIGNED_URL=$PRESIGNED_URL"
fi

echo "==> Done: s3://$BUCKET/$S3_KEY"
