#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
WHITE='\033[1;97m'
RESET='\033[0m'

NGINX_PUBLIC_IPV4=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=NGINX" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].[PublicIpAddress]" \
  --output text
)

echo -e "$CYAN[+] Using GitHub cli 'gh' $RESET"
echo -e "$CYAN[+] Find the possible existing github webhook from the repo $RESET"
WEBHOOK_ID=$(gh api -H "Accept: application/vnd.github+json" repos/$GITHUB_USERNAME/$GITHUB_REPO_NAME/hooks | jq '.[0].id')

echo -e "$CYAN[+] Remove the possible existing github webhook from the repo $RESET"
if [[ $WEBHOOK_ID != "null" ]]
then
  gh api -X DELETE /repos/$GITHUB_USERNAME/$GITHUB_REPO_NAME/hooks/$WEBHOOK_ID
fi

echo -e "$CYAN[+] Create the github webhook from the repo $RESET"
gh api \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  repos/$GITHUB_USERNAME/$GITHUB_REPO_NAME/hooks \
  --input <(printf '{"name":"web", "config":{"url":"https://%s/github-webhook/", "content_type":"application/x-www-form-urlencoded", "insecure_ssl":"1"}, "events":["push"], "active":true}' "$NGINX_PUBLIC_IPV4")
