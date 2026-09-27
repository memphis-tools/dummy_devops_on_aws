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

echo -e "$CYAN[+] Deploy jenkins's user SSH pubkey on Github repo $GITHUB_REPO_NAME $RESET"
./certs_and_stores_commands/deploy_jenkins_user_ssh_pubkey_on_github.sh
echo -e "$GREEN[+] Jenkins's SSH pubkey deployed with read/write scope on $GITHUB_REPO_NAME"

echo -e "$CYAN[+] Deploy Github webhook on $GITHUB_REPO_NAME $RESET"
./certs_and_stores_commands/deploy_job_webhook_on_github.sh
echo -e "$GREEN[+] Github webhook on repo $GITHUB_REPO_NAME created $RESET"

echo -e "$CYAN[+] Setup local ansible project $RESET"
./user_scripts/setup_local_ansible.sh
echo -e "$GREEN[+] Ansible project set $RESET"
