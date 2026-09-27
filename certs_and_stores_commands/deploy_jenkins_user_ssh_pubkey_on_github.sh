#!/bin/bash

set -eu

echo "[+] Remove the jenkins's SSH pubkey from the repo"
KEY_ID=$(gh api -H "Accept: application/vnd.github+json" repos/$GITHUB_USERNAME/$GITHUB_REPO_NAME/keys | jq ".[] | select(.title == \"$JENKINS_SSH_KEY_FILENAME\") | .id")

if [ -n "$KEY_ID" ]; then
  echo "[+] Found key '$JENKINS_SSH_KEY_FILENAME' with ID $KEY_ID. Deleting..."
  gh api --method DELETE -H "Accept: application/vnd.github+json" repos/$GITHUB_USERNAME/$GITHUB_REPO_NAME/keys/$KEY_ID
  echo "[+] Key deleted."
else
  echo "[+] No key titled '$JENKINS_SSH_KEY_FILENAME' found."
fi

echo "[+] Use Github cli to attach the jenkins's SSH pubkey to the repo"
gh repo deploy-key add ./ephemeral-keys/jenkins_github.pub \
  --repo $GITHUB_USERNAME/$GITHUB_REPO_NAME \
  --title $JENKINS_SSH_KEY_FILENAME \
  --allow-write
