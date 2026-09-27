#!/bin/bash

RED='\033[1;31m'
CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Creating AWS secret: $JENKINS_AWS_SECRET_ID_NAME $RESET"
CREATION_FAILED=$(aws secretsmanager create-secret \
    --name $JENKINS_AWS_SECRET_ID_NAME \
    --secret-string "{\"JENKINS_SSH_PASSPHRASE\":\"$JENKINS_SSH_PASSPHRASE\", \"JENKINS_HTTPS_KEYSTORE_PASSWORD\":\"$JENKINS_HTTPS_KEYSTORE_PASSWORD\"}" \
    2>&1)

CREATION_FAILED=$(echo "$CREATION_FAILED" |  grep 'already exists.')
if [[ $CREATION_FAILED != "" ]]
then
  echo -e "$GREEN[+] Secret $JENKINS_AWS_SECRET_ID_NAME already exists $RESET"
else
  echo -e "$GREEN[+] Secret $JENKINS_AWS_SECRET_ID_NAME created $RESET"
fi

echo -e "$CYAN[+] Creating AWS secret: $ANSIBLE_AWS_SECRET_ID_NAME $RESET"
CREATION_FAILED=$(aws secretsmanager create-secret \
    --name $ANSIBLE_AWS_SECRET_ID_NAME \
    --secret-string "{\"ANSIBLE_SSH_PASSPHRASE\":\"$ANSIBLE_SSH_PASSPHRASE\", \"DOCKERHUB_ANSIBLE_RWD_PAT\":\"$DOCKERHUB_ANSIBLE_RWD_PAT\", \"DOCKERHUB_DOCKER_READONLY_PAT\":\"$DOCKERHUB_DOCKER_READONLY_PAT\"}" \
    2>&1)

CREATION_FAILED=$(echo "$CREATION_FAILED" |  grep 'already exists.')
if [[ $CREATION_FAILED != "" ]]
then
  echo -e "$GREEN[+] Secret $ANSIBLE_AWS_SECRET_ID_NAME already exists $RESET"
else
  echo -e "$GREEN[+] Secret $ANSIBLE_AWS_SECRET_ID_NAME created $RESET"
fi


echo -e "$CYAN[+] Creating AWS secret: $DOCKER_AWS_SECRET_ID_NAME $RESET"
CREATION_FAILED=$(aws secretsmanager create-secret \
    --name $DOCKER_AWS_SECRET_ID_NAME \
    --secret-string "{\"DOCKERHUB_DOCKER_READONLY_PAT\":\"$DOCKERHUB_DOCKER_READONLY_PAT\"}" \
    2>&1)

CREATION_FAILED=$(echo "$CREATION_FAILED" |  grep 'already exists.')
if [[ $CREATION_FAILED != "" ]]
then
  echo -e "$GREEN[+] Secret $DOCKER_AWS_SECRET_ID_NAME already exists $RESET"
else
  echo -e "$GREEN[+] Secret $DOCKER_AWS_SECRET_ID_NAME created $RESET"
fi


echo -e "$CYAN[+] Creating AWS secret: $TOMCAT_AWS_SECRET_ID_NAME $RESET"
CREATION_FAILED=$(aws secretsmanager create-secret \
    --name $TOMCAT_AWS_SECRET_ID_NAME \
    --secret-string "{\"TOMCAT_HTTPS_KEYSTORE_PASSWORD\":\"$TOMCAT_HTTPS_KEYSTORE_PASSWORD\"}" \
    2>&1)

CREATION_FAILED=$(echo "$CREATION_FAILED" |  grep 'already exists.')
if [[ $CREATION_FAILED != "" ]]
then
  echo -e "$GREEN[+] Secret $TOMCAT_AWS_SECRET_ID_NAME already exists $RESET"
else
  echo -e "$GREEN[+] Secret $TOMCAT_AWS_SECRET_ID_NAME created $RESET"
fi

echo -e "$CYAN[+] Creating AWS secret: $NGINX_AWS_SECRET_ID_NAME $RESET"
CREATION_FAILED=$(aws secretsmanager create-secret \
    --name $NGINX_AWS_SECRET_ID_NAME \
    --description "Nginx Private Key for SSL" \
    --secret-string file://certs_and_stores/aws_dummy_ops_nginx_jenkins.key \
    2>&1)

CREATION_FAILED=$(echo "$CREATION_FAILED" |  grep 'already exists.')
if [[ $CREATION_FAILED != "" ]]
then
  echo -e "$GREEN[+] Secret $NGINX_AWS_SECRET_ID_NAME already exists $RESET"
else
  echo -e "$GREEN[+] Secret $NGINX_AWS_SECRET_ID_NAME created $RESET"
fi

echo -e "$CYAN[+] Creating AWS secret: $NGINX_PROXY_CLIENT_AWS_SECRET_ID_NAME $RESET"
CREATION_FAILED=$(aws secretsmanager create-secret \
    --name $NGINX_PROXY_CLIENT_AWS_SECRET_ID_NAME \
    --description "Nginx Private Key for SSL" \
    --secret-string file://certs_and_stores/aws_dummy_ops_nginx_jenkins_proxy_client.key \
    2>&1)

CREATION_FAILED=$(echo "$CREATION_FAILED" |  grep 'already exists.')
if [[ $CREATION_FAILED != "" ]]
then
  echo -e "$GREEN[+] Secret $NGINX_PROXY_CLIENT_AWS_SECRET_ID_NAME already exists $RESET"
else
  echo -e "$GREEN[+] Secret $NGINX_PROXY_CLIENT_AWS_SECRET_ID_NAME created $RESET"
fi
