#!/bin/bash

set -u

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Removing AWS certificates $RESET"
aws acm list-certificates --region eu-west-3 --query "CertificateSummaryList[*].CertificateArn" --output text 2>/dev/null | xargs -n1 aws acm delete-certificate --certificate-arn --region eu-west-3 2>/dev/null
echo -e "$GREEN[+] AWS certificates removed $RESET"
