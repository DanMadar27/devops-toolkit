# Repository Replication Scripts

This project provides automated scripts to replicate repositories from source to destination environments. It's particularly useful when you need to create repository mirrors in separate client environments or different organizations.

## Overview

The scripts provide two approaches for repository replication:

- **`clone_copy_repo` (Recommended)**: Clones both repositories normally, copies content (excluding .git), and pushes changes while preserving the original commit messages
- **`mirror_repo` (Legacy)**: Uses `git clone --bare` and `git push --mirror` to create complete repository replicas, including all branches, tags, and commit history

The `clone_copy_repo` approach is preferred as it provides better control over the replication process and preserves meaningful commit history.

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
- `bash scripts/clone_copy_backend.sh`
- `bat scripts/clone_copy_backend.bat`
- `python_scripts/clone_copy_backend.bat` (Windows wrapper for Python script)
- Additional deployment scripts as needed

Note: The legacy mirror scripts (`mirror_backend.sh`, `mirror_nextjs.bat`, `mirror_react.bat`) are still available but `clone_copy_repo` is now the recommended approach.

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

### Python Scripts (Cross-Platform)

For environments with Python 3 installed, you can use the Python implementation which works across all platforms:

1. **Ensure Python 3 is installed:**
   ```bash
   python3 --version
   # or on Windows:
   python --version
   ```

2. **Navigate to the python_scripts directory:**
   ```bash
   cd python_scripts
   ```

3. **Run the Python scripts directly:**
   ```bash
   # Use the core Python script directly
   python3 clone_copy_repo.py "https://github.com/source-org/repo.git" "https://github.com/dest-org/repo.git"
   
   # Or on Windows, use the batch wrapper
   clone_copy_backend.bat
   ```

4. **Make Python script executable (Linux/macOS):**
   ```bash
   chmod +x clone_copy_repo.py
   ./clone_copy_repo.py "https://github.com/source-org/repo.git" "https://github.com/dest-org/repo.git"
   ```

### Windows Environment

If you're on Windows without a Linux shell:

1. **Open Git Bash CMD** (Git Bash provides git commands)
2. **Navigate to the project directory**
3. **Run the deployment script:**
   ```bash
   # Recommended: Use clone_copy_repo approach
   cd "bat scripts"
   ./clone_copy_backend.bat
   
   # Or use Python scripts (if Python is installed)
   cd "python_scripts"
   python clone_copy_repo.py "https://github.com/source-org/repo.git" "https://github.com/dest-org/repo.git"
   # Or use the Windows wrapper:
   clone_copy_backend.bat
   
   # Or use the generic script directly (bash approach)
   cd "bat scripts"
   ./clone_copy_repo.bat "https://github.com/source-org/repo.git" "https://github.com/dest-org/repo.git"
   
   # Legacy: Deploy all repositories (backend, Next.js, and React) using mirror approach
   ./deploy_all.bat
   
   # Or deploy individual components (legacy mirror approach)
   ./mirror_backend.bat
   ./mirror_nextjs.bat
   ./mirror_react.bat
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
   # Recommended: Use clone_copy_repo approach
   cd "bash scripts"
   ./clone_copy_backend.sh
   
   # Or use Python scripts (cross-platform)
   cd "python_scripts"
   python3 clone_copy_repo.py "https://github.com/source-org/repo.git" "https://github.com/dest-org/repo.git"
   
   # Or use the generic bash script directly
   cd "bash scripts"
   ./clone_copy_repo.sh "https://github.com/source-org/repo.git" "https://github.com/dest-org/repo.git"
   
   # Legacy: Deploy individual component using mirror approach
   ./mirror_backend.sh
   
   # Or use the mirror script directly (legacy)
   ./mirror_repo.sh "https://github.com/source-org/repo.git" "https://github.com/dest-org/repo.git"
   ```

## Script Details

### Core Scripts

**Recommended Approach:**
- **`clone_copy_repo.sh`** / **`clone_copy_repo.bat`** / **`clone_copy_repo.py`**: Core repository copying functionality that clones both repositories, copies content, and preserves commit messages
- **`clone_copy_backend.sh`** / **`clone_copy_backend.bat`** / **`python_scripts/clone_copy_backend.bat`**: Copies backend repository using the clone_copy approach

**Legacy Mirror Approach:**
- **`mirror_repo.sh`** / **`mirror_repo.bat`**: Core mirroring functionality that handles the git operations using bare clone and mirror push
- **`mirror_backend.sh`** / **`mirror_backend.bat`**: Mirrors backend repository
- **`mirror_nextjs.bat`**: Mirrors Next.js frontend repository  
- **`mirror_react.bat`**: Mirrors React frontend repository
- **`deploy_all.bat`**: Runs all deployment scripts in sequence

### How It Works

**Clone Copy Approach (Recommended):**
1. **Clone**: Creates normal clones of both source and destination repositories
2. **Copy**: Copies all content from source to destination (excluding .git directory)
3. **Commit**: Commits changes using the original commit message from the source repository
4. **Push**: Pushes changes to the destination repository
5. **Cleanup**: Removes temporary directories

**Available implementations:**
- **Bash script** (`bash scripts/clone_copy_repo.sh`): For Linux/macOS environments
- **Batch script** (`bat scripts/clone_copy_repo.bat`): For Windows environments
- **Python script** (`python_scripts/clone_copy_repo.py`): Cross-platform solution requiring Python 3

**Mirror Approach (Legacy):**
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