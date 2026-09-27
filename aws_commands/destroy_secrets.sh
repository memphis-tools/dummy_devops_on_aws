#!/bin/bash

set -u

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Removing AWS secrets $RESET"
aws secretsmanager delete-secret --secret-id $TOMCAT_AWS_SECRET_ID_NAME --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id $JENKINS_AWS_SECRET_ID_NAME --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id $ANSIBLE_AWS_SECRET_ID_NAME --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id $DOCKER_AWS_SECRET_ID_NAME --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id $NGINX_AWS_SECRET_ID_NAME --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id $NGINX_PROXY_CLIENT_AWS_SECRET_ID_NAME --force-delete-without-recovery
echo -e "$GREEN[+] AWS secrets removed $RESET"
