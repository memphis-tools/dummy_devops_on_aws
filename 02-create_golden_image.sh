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

echo -e "$CYAN[+] Trying to build the default AWS golden image $RESET"
AMI_ID=$(./aws_commands/build_ami_golden_image.sh | grep -E -m1 'ami-[0-9a-f]+')
echo -e "$GREEN[+] Default golden AMI built with id: $AMI_ID $RESET"
