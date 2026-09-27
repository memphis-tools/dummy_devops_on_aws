#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Removing any 'aws-dummy-ops-*' entries from /etc/hosts $RESET"
sudo sed -e '/aws-dummy-ops/d' -i /etc/hosts
echo -e "$GREEN[+] Successfully removed all 'aws-dummy-ops-*' entries from /etc/hosts $RESET"

echo -e "$CYAN[+] Get the project instances public ipv4 $RESET"
JENKINS_PUBLIC_IP=$(terraform -chdir=terraform output -raw jenkins_public_ip)
echo -e "$GREEN[+] jenkins public ipv4: $JENKINS_PUBLIC_IP $RESET"
TOMCAT_PUBLIC_IP=$(terraform -chdir=terraform output -raw tomcat_public_ip)
echo -e "$GREEN[+] tomcat public ipv4: $TOMCAT_PUBLIC_IP $RESET"
DOCKER_PUBLIC_IP=$(terraform -chdir=terraform output -raw docker_public_ip)
echo -e "$GREEN[+] docker public ipv4: $DOCKER_PUBLIC_IP $RESET"
K8S_PUBLIC_IP=$(terraform -chdir=terraform output -raw k8s_public_ip)
echo -e "$GREEN[+] k8s public ipv4: $K8S_PUBLIC_IP $RESET"
ANSIBLE_PUBLIC_IP=$(terraform -chdir=terraform output -raw ansible_public_ip)
echo -e "$GREEN[+] ansible public ipv4: $ANSIBLE_PUBLIC_IP $RESET"
NGINX_PUBLIC_IP=$(terraform -chdir=terraform output -raw nginx_public_ip)
echo -e "$GREEN[+] nginx public ipv4: $NGINX_PUBLIC_IP $RESET"
WAZUH_DASHBOARD_PUBLIC_IP=$(terraform -chdir=terraform output -raw wazuh_dashboard_public_ip)
echo -e "$GREEN[+] wazuh dashboard public ipv4: $WAZUH_DASHBOARD_PUBLIC_IP $RESET"
WAZUH_INDEXER_PUBLIC_IP=$(terraform -chdir=terraform output -raw wazuh_indexer_public_ip)
echo -e "$GREEN[+] wazuh indexer public ipv4: $WAZUH_INDEXER_PUBLIC_IP $RESET"
WAZUH_SERVER_PUBLIC_IP=$(terraform -chdir=terraform output -raw wazuh_server_public_ip)
echo -e "$GREEN[+] wazuh server public ipv4: $WAZUH_SERVER_PUBLIC_IP $RESET"

echo -e "$CYAN[+] Update /etc/hosts $RESET"
echo "$JENKINS_PUBLIC_IP aws-dummy-ops-jenkins.lab" | sudo tee -a /etc/hosts > /dev/null
echo "$TOMCAT_PUBLIC_IP aws-dummy-ops-tomcat.lab" | sudo tee -a /etc/hosts > /dev/null
echo "$DOCKER_PUBLIC_IP aws-dummy-ops-docker-tomcat.lab" | sudo tee -a /etc/hosts > /dev/null
echo "$K8S_PUBLIC_IP aws-dummy-ops-k8s.lab" | sudo tee -a /etc/hosts > /dev/null
echo "$ANSIBLE_PUBLIC_IP aws-dummy-ops-ansible.lab" | sudo tee -a /etc/hosts > /dev/null
echo "$NGINX_PUBLIC_IP aws-dummy-ops-nginx.lab" | sudo tee -a /etc/hosts > /dev/null
echo "$WAZUH_DASHBOARD_PUBLIC_IP aws-dummy-ops-wazuh-dashboard.lab" | sudo tee -a /etc/hosts > /dev/null
echo "$WAZUH_INDEXER_PUBLIC_IP aws-dummy-ops-wazuh-indexer.lab" | sudo tee -a /etc/hosts > /dev/null
echo "$WAZUH_SERVER_PUBLIC_IP aws-dummy-ops-wazuh-server.lab" | sudo tee -a /etc/hosts > /dev/null

echo -e "$GREEN[+] Successfully updated /etc/hosts $RESET"
