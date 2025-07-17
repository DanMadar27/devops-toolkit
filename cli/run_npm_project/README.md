# NPM Project Runner

A bash script that automatically launches multiple NPM projects in separate terminal tabs with specific Node.js versions.

## Features

- **Multi-project support**: Launch multiple NPM projects simultaneously
- **Node.js version management**: Automatically switches to specified Node.js versions using NVM
- **Cross-terminal compatibility**: Works with GNOME Terminal and Konsole
- **Graceful error handling**: Exits immediately on command failures
- **Interactive tabs**: Each project runs in its own terminal tab with custom titles

## Prerequisites

- **NVM (Node Version Manager)**: Must be installed and configured
- **Supported terminal**: GNOME Terminal or Konsole
- **Node.js versions**: The specified versions must be installed via NVM

## Configuration

Edit the `repos` array in `run_project.sh` to configure your projects:

```bash
repos=(
  "/path/to/your/project|v20.12.0|dev|Project Name"
  "/another/project/path|v16.20.2|start|Another Project"
)
```

Each entry follows the format: `path|node_version|npm_command|tab_title`

- **path**: Absolute path to your NPM project directory
- **node_version**: Node.js version to use (must be installed via NVM)
- **npm_command**: NPM script to run (e.g., "dev", "start", "build")
- **tab_title**: Display name for the terminal tab

## Usage

1. Make the script executable:
   ```bash
   chmod +x run_project.sh
   ```

2. Run the script:
   ```bash
   ./run_project.sh
   ```

## What it does

For each configured project, the script:

1. Opens a new terminal tab with the specified title
2. Navigates to the project directory
3. Loads NVM and switches to the specified Node.js version
4. Runs `npm install` to ensure dependencies are up to date
5. Executes the specified NPM command
6. Sets up a trap to handle Ctrl+C gracefully
7. Keeps the terminal open after the command completes

## Error Handling

- Script exits immediately if any command fails (`set -eo pipefail`)
- Each tab handles directory navigation errors
- NVM version switching failures are caught
- Graceful shutdown on Ctrl+C with user prompt

## Terminal Support

- **GNOME Terminal**: Full support with `--tab` and `--title` options
- **Konsole**: Full support with `--new-tab` and `--title` options
- **macOS Terminal**: Detection included but implementation pending
- **Other terminals**: Will show an error