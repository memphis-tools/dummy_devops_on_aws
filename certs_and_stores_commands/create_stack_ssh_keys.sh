#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
WHITE='\033[1;97m'
RESET='\033[0m'

echo -e "$CYAN[+] Source environment vars from .env file $RESET"
source .env
echo -e "$GREEN[+] File .env sourced $RESET"

echo -e "[+] Create locally the jenkins SSH keypair (used to address github) $RESET"
# Use RSA 4096-bit keys in PEM format if you need passphrase-protected Jenkins SSH credentials.
ssh-keygen -t rsa -b 4096 -m PEM -f ./ephemeral-keys/$JENKINS_SSH_KEY_FILENAME -N $JENKINS_SSH_PASSPHRASE -C $JENKINS_SSH_USER_USERNAME@$JENKINS_SSH_USER_HOSTNAME

echo -e "[+] Create locally the ansible SSH keypair (used to address docker) $RESET"
ssh-keygen -t ed25519 -f ./ephemeral-keys/$ANSIBLE_SSH_KEY_FILENAME -N $ANSIBLE_SSH_PASSPHRASE
