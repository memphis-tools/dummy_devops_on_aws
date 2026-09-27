#!/bin/bash
set -u

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Destroy the dynamodb table if exists: terraform-state-lock $RESET"
aws dynamodb delete-table --table-name terraform-state-lock
echo -e "$GREEN[+] AWS dynamodb table removed $RESET"
