#!/bin/bash

# Enable fail-fast (exit immediately if any command fails)
set -e

# Set the source and destination repositories
SOURCE_REPO="REPLACE_WITH_ACTUAL_SOURCE_REPO"
DESTINATION_REPO="REPLACE_WITH_ACTUAL_REPO"

# Call the generic copy script (clone_copy_repo.sh in the same directory)
echo "Calling clone_copy_repo.sh to clone copy $SOURCE_REPO to $DESTINATION_REPO"
./clone_copy_repo.sh "$SOURCE_REPO" "$DESTINATION_REPO"

echo "Deployed Backend successfully"
