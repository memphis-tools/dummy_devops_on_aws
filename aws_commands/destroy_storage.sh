#!/bin/bash
set -u

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Empty the bucket: dummy-devops-terraform-state-bucket $RESET"
aws s3 rm s3://dummy-devops-terraform-state-bucket --recursive

echo -e "$CYAN[+] Delete the bucket: dummy-devops-terraform-state-bucket $RESET"
aws s3api delete-bucket --bucket dummy-devops-terraform-state-bucket

echo -e "$GREEN[+] AWS bucket removed $RESET"
