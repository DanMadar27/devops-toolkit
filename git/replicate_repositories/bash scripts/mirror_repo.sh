#!/bin/bash

# Enable fail-fast (exit immediately if any command fails)
set -e

# Check if both source and destination repository URLs are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source_repo_url> <destination_repo_url>"
    exit 1
fi

# Get source and destination repository URLs
SOURCE_REPO=$1
DESTINATION_REPO=$2

# Extract the repository name by removing everything before the last "/"
# This assumes the repo URL is in the form of "https://github.com/user/repo.git"
REPO_NAME=$(basename "$SOURCE_REPO" .git)

# Remove the existing repository directory if it exists
echo "Repository name is: $REPO_NAME"
if [ -d "$REPO_NAME.git" ]; then
    echo "Removing existing directory: $REPO_NAME.git"
    rm -rf "$REPO_NAME.git"  # Delete the directory and its contents
fi

# Clone the source repository as a mirror
echo "Cloning source repository: $SOURCE_REPO"
git clone --bare "$SOURCE_REPO"

# Change to the repository directory (this will be the cloned repository)
cd "$REPO_NAME.git"

# Setting up the destination repository remote (make sure it exists in the destination organization)
echo "Setting up destination repository: $DESTINATION_REPO"
git remote set-url --push origin "$DESTINATION_REPO"

# Push the mirrored repository to the destination org
echo "Pushing mirror to destination repository"
git push --mirror "$DESTINATION_REPO"

# Optionally, verify the remote repository after pushing
git remote -v

echo "Repository mirror completed successfully."
