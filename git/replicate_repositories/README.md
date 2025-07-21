# Repository Replication Scripts

This project provides automated scripts to replicate repositories from source to destination environments. It's particularly useful when you need to create repository mirrors in separate client environments or different organizations.

## Overview

The scripts use `git clone --bare` and `git push --mirror` to create complete repository replicas, including all branches, tags, and commit history.

## Prerequisites

Before using these scripts, you **must** configure the source and destination repository URLs:

### 1. Repository Access Requirements
- **Git credentials**: Ensure you have read access to the source repository and write access to the destination repository
- **Authentication**: Set up appropriate authentication (SSH keys, personal access tokens, or cached credentials)
- **Destination repository**: The destination repository must already exist in the target organization/account

### 2. Configure Repository URLs

**Important**: You must edit the deployment scripts to replace the placeholder values with your actual repository URLs.

In each deployment script, update these variables:
```bash
# Replace these placeholders with your actual repository URLs
SOURCE_REPO="REPLACE_WITH_ACTUAL_SOURCE_REPO"        # Example: "https://github.com/original-org/backend-app.git"
DESTINATION_REPO="REPLACE_WITH_ACTUAL_REPO"          # Example: "https://github.com/client-org/backend-app.git"
```

**Files to update:**
- `bash scripts/deploy_backend.sh`
- `bat scripts/deploy_backend.bat`
- `bat scripts/deploy_nextjs.bat` 
- `bat scripts/deploy_react.bat`

### 3. Authentication Setup

For seamless operation, configure Git credentials:

**Option A: SSH Keys (Recommended)**
```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Add to your Git service (GitHub, GitLab, etc.)
cat ~/.ssh/id_rsa.pub
```

**Option B: Personal Access Token**
```bash
# Cache credentials to avoid repeated prompts
git config --global credential.helper cache
```

**Option C: Browser-Based Authentication**

Just run the scripts and wait for git to ask you for browser signing.

## Usage

### Windows Environment

If you're on Windows without a Linux shell:

1. **Open Git Bash CMD** (Git Bash provides git commands)
2. **Navigate to the project directory**
3. **Run the deployment script:**
   ```bash
   # Deploy all repositories (backend, Next.js, and React)
   cd "bat scripts"
   ./deploy_all.bat
   
   # Or deploy individual components
   ./deploy_backend.bat
   ./deploy_nextjs.bat
   ./deploy_react.bat
   ```

4. **Reset credentials if needed:**
   ```bash
   git credential-cache exit
   ```
   Or in Windows: search for "Credentials Manager" -> Windows Manager -> Delete desired credentials (git)

### Linux/macOS Environment

For Unix-based systems:

1. **Make scripts executable:**
   ```bash
   chmod +x "bash scripts"/*.sh
   ```

2. **Run deployment scripts:**
   ```bash
   # Deploy individual component
   cd "bash scripts"
   ./deploy_backend.sh
   
   # Or use the mirror script directly
   ./mirror_repo.sh "https://github.com/source-org/repo.git" "https://github.com/dest-org/repo.git"
   ```

## Script Details

### Core Scripts

- **`mirror_repo.sh`** / **`mirror_repo.bat`**: Core mirroring functionality that handles the git operations
- **`deploy_backend.sh`** / **`deploy_backend.bat`**: Mirrors backend repository
- **`deploy_nextjs.bat`**: Mirrors Next.js frontend repository  
- **`deploy_react.bat`**: Mirrors React frontend repository
- **`deploy_all.bat`**: Runs all deployment scripts in sequence

### How It Works

1. **Clone**: Creates a bare clone of the source repository
2. **Configure**: Sets up the destination repository as the push remote
3. **Mirror**: Pushes all branches, tags, and history to the destination
4. **Cleanup**: Removes temporary files
5. **Verify**: Shows remote configuration for confirmation

## Troubleshooting

### Common Issues

**Authentication Errors:**
```bash
# Clear cached credentials
git credential-cache exit

# Or configure credentials globally
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

**Permission Denied:**
- Verify you have write access to the destination repository
- Check that your SSH keys or access tokens are properly configured
- Ensure the destination repository exists

**Repository Already Exists:**
- The script will automatically remove and recreate local temporary directories
- Ensure the destination repository is empty or you have force-push permissions

## Security Notes

- Never commit actual repository URLs to version control
- Use environment variables or config files for sensitive repository information
- Regularly rotate access tokens and SSH keys
- Review permissions on destination repositories