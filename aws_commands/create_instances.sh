#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Prepare your working directory for other commands$RESET"
terraform -chdir=terraform init
echo -e "$GREEN[+] Terraform init is ok $RESET"

echo -e "$CYAN[+] Show changes required by the current configuration $RESET"
terraform -chdir=terraform plan -out=tfplan.out -var="golden_image_id=$1" -input=false
echo -e "$GREEN[+] Terraform plan is ok $RESET"

echo -e "$CYAN[+] Create/Update infrastructure $RESET"
terraform -chdir=terraform apply -var="golden_image_id=$1" -auto-approve
