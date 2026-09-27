#!/bin/bash

set -eu

unset AMI_ID

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Ensure SSH AWS's pivate key loaded $RESET"
eval $(ssh-agent)
ssh-add $USER_PRIVATEKEY_PATH
echo -e "$GREEN[+] SSH private key loaded $RESET"

echo -e "$CYAN[+] Check if the AWS credentials exist $RESET"
aws configure list
echo -e "$GREEN[+] AWS credentials exist $RESET"

echo -e "$CYAN[+] Update your local DNS records and trust the created CA $RESET"
./user_scripts/setup_your_local_dns_resolver.sh
echo -e "$GREEN[+] Local DNS records updated $RESET"
./user_scripts/setup_your_trust_self_signed_ca.sh
echo -e "$GREEN[+] Self signed CA trusted $RESET"
