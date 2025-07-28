#!/bin/bash

# Enable fail-fast (exit immediately if any command fails)
set -e

echo "Cloning and copying backend repository..."
python3 ./clone_copy_repo.py <source_repo_url> <destination_repo_url>
echo "Backend repository cloned and copied successfully."
