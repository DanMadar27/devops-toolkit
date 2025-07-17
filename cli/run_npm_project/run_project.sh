#!/bin/bash
set -eo pipefail  # Exit immediately if a command fails

# Define repositories configuration
repos=(
  "/path/to/repo|v20.12.0|dev|Repo 1"
  "/path/to/repo|v14.21.3|develop|Repo 2"
  "/path/to/repo|v16.20.2|dev|Repo 3"
)

# Detect terminal type
if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
  terminal="mac"
elif command -v gnome-terminal >/dev/null; then
  terminal="gnome"
elif command -v konsole >/dev/null; then
  terminal="konsole"
else
  echo "Unsupported terminal. Install gnome-terminal or konsole."
  exit 1
fi

for repo in "${repos[@]}"; do
  IFS="|" read -r folder version command title <<< "$repo"

  echo "Launching '$title' in a new tab..."

  if [[ "$terminal" == "gnome" ]]; then
    gnome-terminal --tab --title="$title" -- bash -c "
      cd '$folder' || exit 1;
      source ~/.nvm/nvm.sh;
      nvm use '$version' || exit 1;
      npm install;

      trap 'echo \"Stopped by user. Press Enter to exit...\"; read' SIGINT

      npm run '$command';
      exec bash"
  elif [[ "$terminal" == "konsole" ]]; then
    konsole --new-tab --title "$title" -e bash -c "
      cd '$folder' || exit 1;
      source ~/.nvm/nvm.sh;
      nvm use '$version' || exit 1;
      npm install;

      trap 'echo \"Stopped by user. Press Enter to exit...\"; read' SIGINT

      npm run '$command';
      exec bash"
  fi
done
