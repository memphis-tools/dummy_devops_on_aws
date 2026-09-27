#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Your current ipv4 ip is : $TF_VAR_authorized_ip $RESET"
read -p 'Is it correct, do you want to continue ?' ANSWER
if [[ $ANSWER =~ ^[Nn][oO]?$ ]]
then
  exit 0
fi

echo -e "$CYAN[+] Ensure SSH AWS's pivate key loaded $RESET"
eval $(ssh-agent)
ssh-add $USER_PRIVATEKEY_PATH
echo -e "$GREEN[+] SSH private key loaded $RESET"

echo -e "$CYAN[+] Check if the AWS credentials exist $RESET"
aws configure list
echo -e "$GREEN[+] AWS credentials exist $RESET"

echo -e "$CYAN[+] Create any needed SSH keypairs in your ./ephemeral-keys $RESET"
./certs_and_stores_commands/create_stack_ssh_keys.sh
echo -e "$GREEN[+] SSH keypairs created"

echo -e "$CYAN[+] Trying to create self signed certs $RESET"
./certs_and_stores_commands/create_self_signed_certs.sh
echo -e "$GREEN[+] Self signed certs created $RESET"

echo -e "$CYAN[+] Trying to create keystores and trustores $RESET"
./certs_and_stores_commands/create_keystore_and_truststore.sh
echo -e "$GREEN[+] Keystores and trustores  created $RESET"

echo -e "$CYAN[+] Trying to create default AWS VPC $RESET"
./aws_commands/create_default_vpc.sh
echo -e "$GREEN[+] Default AWS VPC created $RESET"

echo -e "$CYAN[+] Trying to create default AWS S3 storage $RESET"
./aws_commands/create_default_storage.sh
echo -e "$GREEN[+] Default AWS S3 storage created $RESET"

echo -e "$CYAN[+] Trying to create default AWS Dynamodb table $RESET"
./aws_commands/create_default_terraform_dynamodb_table.sh
echo -e "$GREEN[+] Default AWS Dynamodb table created $RESET"

echo -e "$CYAN[+] Trying to create AWS secrets $RESET"
./aws_commands/create_secrets.sh
echo -e "$GREEN[+] AWS secrets created $RESET"
