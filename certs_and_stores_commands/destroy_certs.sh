#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
WHITE='\033[1;97m'
RESET='\033[0m'

echo -e "$CYAN[+] Trying to remove any ./certs_and_stores/aws_* files $RESET"
rm -f ./certs_and_stores/aws_*
echo -e "$GREEN[+] ./certs_and_stores/aws_* files removed $RESET"
