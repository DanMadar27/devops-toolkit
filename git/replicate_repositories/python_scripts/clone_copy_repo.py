import os
import sys
import shutil
import subprocess
import argparse
from pathlib import Path

def run_command(command, cwd=None, check=True):
    """Run a shell command and return the result."""
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            check=check,
            capture_output=True,
            text=True
        )
        return result
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {command}")
        print(f"Error: {e.stderr}")
        sys.exit(1)

def get_repo_name(repo_url):
    """Extract repository name from URL."""
    repo_name = os.path.basename(repo_url)
    if repo_name.endswith('.git'):
        repo_name = repo_name[:-4]
    return repo_name

def remove_existing_directory(directory):
    """Remove existing directory if it exists."""
    if os.path.exists(directory):
        print(f"Removing existing directory: {directory}")
        shutil.rmtree(directory)

def clone_repository(repo_url, repo_name):
    """Clone a repository."""
    print(f"Cloning repository: {repo_url}")
    run_command(f"git clone {repo_url}")

def copy_content(source_dir, dest_dir):
    """Copy content from source to destination, excluding .git directory."""
    print("Copying content from source to destination repository")
    
    for root, dirs, files in os.walk(source_dir):
        # Skip .git directories
        if '.git' in dirs:
            dirs.remove('.git')
        
        for file in files:
            source_file = os.path.join(root, file)
            # Calculate relative path from source directory
            relative_path = os.path.relpath(source_file, source_dir)
            dest_file = os.path.join(dest_dir, relative_path)
            
            # Create destination directory if it doesn't exist
            dest_file_dir = os.path.dirname(dest_file)
            os.makedirs(dest_file_dir, exist_ok=True)
            
            # Copy the file
            shutil.copy2(source_file, dest_file)

def get_last_commit_message(repo_dir):
    """Get the last commit message from a repository."""
    result = run_command('git log -1 --pretty=format:"%s"', cwd=repo_dir)
    return result.stdout.strip().strip('"')

def has_staged_changes(repo_dir):
    """Check if there are staged changes in the repository."""
    result = run_command('git diff --staged --quiet', cwd=repo_dir, check=False)
    return result.returncode != 0

def main():
    parser = argparse.ArgumentParser(
        description='Clone source repository and copy its content to destination repository'
    )
    parser.add_argument('source_repo', help='Source repository URL')
    parser.add_argument('destination_repo', help='Destination repository URL')
    
    args = parser.parse_args()
    
    source_repo = args.source_repo
    destination_repo = args.destination_repo
    
    # Extract repository names
    source_repo_name = get_repo_name(source_repo)
    destination_repo_name = get_repo_name(destination_repo)
    
    print(f"Source repository name: {source_repo_name}")
    print(f"Destination repository name: {destination_repo_name}")
    
    # Remove existing directories if they exist
    remove_existing_directory(source_repo_name)
    remove_existing_directory(destination_repo_name)
    
    try:
        # Clone repositories
        clone_repository(source_repo, source_repo_name)
        clone_repository(destination_repo, destination_repo_name)
        
        # Copy content from source to destination
        copy_content(source_repo_name, destination_repo_name)
        
        # Get the last commit message from source repository
        last_commit_message = get_last_commit_message(source_repo_name)
        print(f"Last commit message from source repository: {last_commit_message}")
        
        # Change to destination repository and commit changes
        os.chdir(destination_repo_name)
        
        # Add all changes
        run_command('git add .')
        
        # Check if there are any changes to commit
        if not has_staged_changes('.'):
            print("No changes to commit. Repositories might already be in sync.")
        else:
            # Commit the changes
            print("Committing changes to destination repository")
            run_command(f'git commit -m "{last_commit_message}"')
            
            # Push changes to destination repository
            print("Pushing changes to destination repository")
            run_command('git push origin')
        
        print("Repository copy completed successfully.")
        
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()