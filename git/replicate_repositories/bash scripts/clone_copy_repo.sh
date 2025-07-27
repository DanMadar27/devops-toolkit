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

# Extract repository names
SOURCE_REPO_NAME=$(basename "$SOURCE_REPO" .git)
DESTINATION_REPO_NAME=$(basename "$DESTINATION_REPO" .git)

echo "Source repository name: $SOURCE_REPO_NAME"
echo "Destination repository name: $DESTINATION_REPO_NAME"

# Remove existing directories if they exist
if [ -d "$SOURCE_REPO_NAME" ]; then
    echo "Removing existing source directory: $SOURCE_REPO_NAME"
    rm -rf "$SOURCE_REPO_NAME"
fi

if [ -d "$DESTINATION_REPO_NAME" ]; then
    echo "Removing existing destination directory: $DESTINATION_REPO_NAME"
    rm -rf "$DESTINATION_REPO_NAME"
fi

# Clone the source repository
echo "Cloning source repository: $SOURCE_REPO"
git clone "$SOURCE_REPO"

# Clone the destination repository
echo "Cloning destination repository: $DESTINATION_REPO"
git clone "$DESTINATION_REPO"

# Copy content from source to destination (excluding .git directory)
echo "Copying content from source to destination repository"
cd "$SOURCE_REPO_NAME"
find . -name ".git" -prune -o -type f -print | while read file; do
    # Skip .git directory
    if [[ "$file" != *".git"* ]]; then
        # Create directory structure in destination if it doesn't exist
        dest_dir="../$DESTINATION_REPO_NAME/$(dirname "$file")"
        mkdir -p "$dest_dir"
        # Copy the file
        cp "$file" "../$DESTINATION_REPO_NAME/$file"
    fi
done

# Get the last commit message from source repository
cd "../$SOURCE_REPO_NAME"
LAST_COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
echo "Last commit message from source repository: $LAST_COMMIT_MESSAGE"

# Change to destination repository and commit changes
cd "../$DESTINATION_REPO_NAME"

# Add all changes
git add .

# Check if there are any changes to commit
if git diff --staged --quiet; then
    echo "No changes to commit. Repositories might already be in sync."
else
    # Commit the changes
    echo "Committing changes to destination repository"
    git commit -m "$LAST_COMMIT_MESSAGE"
    
    # Push changes to destination repository
    echo "Pushing changes to destination repository"
    git push origin
fi

echo "Repository copy completed successfully."