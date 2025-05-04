#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# Script to identify old Git branches (no commits within 60 days) and notify via Slack

# set slack webhook URL
export SLACK_WEBHOOK="your-webhook-url"

DAYS_OLD=60
NOW=$(date +%s)
OLD_BRANCHES=""

# Get repository name
REPO_NAME=$(basename -s .git $(git config --get remote.origin.url))
if [[ -z "$REPO_NAME" ]]; then
  # Alternative method if the first one fails
  REPO_NAME=$(git rev-parse --show-toplevel | xargs basename)
fi

# Ensure we're seeing what GitHub shows: update refs and remove stale ones
git fetch origin --prune

# Save the output to a temporary file instead of using a pipe
git for-each-ref --format="%(refname:short) %(committerdate:unix)" refs/remotes/origin/ > /tmp/branches_data.txt

# Now process the file - changes to OLD_BRANCHES will persist
while read -r BRANCH DATE; do
  NAME=${BRANCH#origin/}
  AGE=$(( (NOW - DATE) / 86400 ))

  if [[ $AGE -gt $DAYS_OLD && "$NAME" != "main" && "$NAME" != "master" ]]; then
    OLD_BRANCHES+="$NAME (last commit ${AGE} days ago)\n"
  fi
done < /tmp/branches_data.txt

# Check if Slack webhook is configured
if [[ -z "$SLACK_WEBHOOK" ]]; then
  echo "Error: SLACK_WEBHOOK environment variable not set"
  exit 1
fi

# Send to Slack if any found
if [[ -n "$OLD_BRANCHES" ]]; then
  # Echo the message with interpreted escape sequences
  SLACK_MESSAGE=$(echo -e "⚠️ *Old Git Branches Detected in \`${REPO_NAME}\`:*\n$OLD_BRANCHES")
  echo "$SLACK_MESSAGE"
  
  # Use printf to properly handle the newlines for JSON
  PAYLOAD=$(printf '{"text": "%s"}' "$(echo "$SLACK_MESSAGE" | sed 's/"/\\"/g')")
  
  curl -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK"
else
  echo "No old branches found in ${REPO_NAME}."
fi