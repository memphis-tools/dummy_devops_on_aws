#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Get the project instances public (and private ipv4) $RESET"
JENKINS_PUBLIC_IP=$(terraform -chdir=terraform output -raw jenkins_public_ip)
JENKINS_PRIVATE_IP=$(terraform -chdir=terraform output -raw jenkins_private_ip)
echo -e "$GREEN[+] jenkins public ipv4: $JENKINS_PUBLIC_IP $RESET"
TOMCAT_PUBLIC_IP=$(terraform -chdir=terraform output -raw tomcat_public_ip)
TOMCAT_PRIVATE_IP=$(terraform -chdir=terraform output -raw tomcat_private_ip)
echo -e "$GREEN[+] tomcat public ipv4: $TOMCAT_PUBLIC_IP $RESET"
DOCKER_PUBLIC_IP=$(terraform -chdir=terraform output -raw docker_public_ip)
DOCKER_PRIVATE_IP=$(terraform -chdir=terraform output -raw docker_private_ip)
echo -e "$GREEN[+] docker public ipv4: $DOCKER_PUBLIC_IP $RESET"
ANSIBLE_PUBLIC_IP=$(terraform -chdir=terraform output -raw ansible_public_ip)
ANSIBLE_PRIVATE_IP=$(terraform -chdir=terraform output -raw ansible_private_ip)
echo -e "$GREEN[+] ansible public ipv4: $ANSIBLE_PUBLIC_IP $RESET"
NGINX_PUBLIC_IP=$(terraform -chdir=terraform output -raw nginx_public_ip)
NGINX_PRIVATE_IP=$(terraform -chdir=terraform output -raw nginx_private_ip)
echo -e "$GREEN[+] nginx public ipv4: $NGINX_PUBLIC_IP $RESET"
WAZUH_DASHBOARD_PUBLIC_IP=$(terraform -chdir=terraform output -raw wazuh_dashboard_public_ip)
WAZUH_DASHBOARD_PRIVATE_IP=$(terraform -chdir=terraform output -raw wazuh_dashboard_private_ip)
echo -e "$GREEN[+] wazuh public and private ipv4: $WAZUH_DASHBOARD_PUBLIC_IP $RESET"
WAZUH_INDEXER_PUBLIC_IP=$(terraform -chdir=terraform output -raw wazuh_indexer_public_ip)
WAZUH_INDEXER_PRIVATE_IP=$(terraform -chdir=terraform output -raw wazuh_indexer_private_ip)
echo -e "$GREEN[+] wazuh public and private ipv4: $WAZUH_INDEXER_PUBLIC_IP $RESET"
WAZUH_SERVER_PUBLIC_IP=$(terraform -chdir=terraform output -raw wazuh_server_public_ip)
WAZUH_SERVER_PRIVATE_IP=$(terraform -chdir=terraform output -raw wazuh_server_private_ip)
echo -e "$GREEN[+] wazuh public and private ipv4: $WAZUH_SERVER_PUBLIC_IP $RESET"
K8S_PUBLIC_IP=$(terraform -chdir=terraform output -raw k8s_public_ip)
K8S_PRIVATE_IP=$(terraform -chdir=terraform output -raw k8s_private_ip)
echo -e "$GREEN[+] k8s bootstrap server public and private ipv4: $K8S_PUBLIC_IP $RESET"


echo -e "$CYAN[+] Update ansible's inventori.ini $RESET"
cat > ansible/inventory.ini <<EOF
[active]
jenkins ansible_host=$JENKINS_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key ansible_python_interpreter=/opt/jenkins-venv/bin/python
tomcat ansible_host=$TOMCAT_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key
docker ansible_host=$DOCKER_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key
k8s ansible_host=$K8S_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key
ansible ansible_host=$ANSIBLE_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key
nginx ansible_host=$NGINX_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key
wazuh_dashboard ansible_host=$WAZUH_DASHBOARD_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key
wazuh_server ansible_host=$WAZUH_SERVER_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key
wazuh_indexer ansible_host=$WAZUH_INDEXER_PUBLIC_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/aws_2025_devops/aws_terraform_remote_exec_key
EOF
echo -e "$GREEN[+] The ansible's inventori.ini is set $RESET"

echo -e "$CYAN[+] Copy the instances certs and stores into the ansible/roles/setup_***_on_tls/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_jenkins_fullchain.crt ansible/roles/setup_stack_trusts/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_jenkins_fullchain.crt into ansible/roles/setup_stack_trusts/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_tomcat_fullchain.crt ansible/roles/setup_stack_trusts/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_tomcat_fullchain.crt into ansible/roles/setup_stack_trusts/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_docker_tomcat_fullchain.crt ansible/roles/setup_stack_trusts/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_docker_tomcat_fullchain.crt into ansible/roles/setup_stack_trusts/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_nginx_jenkins_fullchain.crt ansible/roles/setup_stack_trusts/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_nginx_jenkins_fullchain.crt into ansible/roles/setup_stack_trusts/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_nginx_jenkins_proxy_client_fullchain.crt ansible/roles/setup_stack_trusts/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_nginx_jenkins_proxy_client_fullchain.crt into ansible/roles/setup_stack_trusts/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_wazuh_server_fullchain.crt ansible/roles/setup_stack_trusts/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_wazuh_server_fullchain.crt into ansible/roles/setup_stack_trusts/files $RESET"

cp ./ephemeral-keys/aws_dummy_ops_jenkins.keystore ansible/roles/setup_jenkins_on_tls/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_jenkins.keystore into ansible/roles/setup_jenkins_on_tls/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_tomcat.keystore ansible/roles/setup_tomcat_on_tls/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_tomcat.keystore into ansible/roles/setup_tomcat_on_tls/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_docker_tomcat.keystore ansible/roles/setup_docker_on_tls/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_docker_tomcat.keystore into ansible/roles/setup_docker_on_tls/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_docker_tomcat.keystore ansible/roles/setup_ansible_config/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_docker_tomcat.keystore into ansible/roles/setup_ansible_config/files $RESET"
cp ./ephemeral-keys/aws_dummy_ops_docker_tomcat.keystore ansible/roles/setup_k8s_dummy_app/files
echo -e "$GREEN[+] Successfully copied aws_dummy_ops_docker_tomcat.keystore into ansible/roles/setup_k8s_dummy_app/files $RESET"

cp ./ephemeral-keys/aws_dummy_ops_nginx_jenkins.crt ansible/roles/setup_nginx_on_tls/files
cp ./ephemeral-keys/aws_dummy_ops_nginx_jenkins_fullchain.crt ansible/roles/setup_nginx_on_tls/files
cp ./ephemeral-keys/aws_dummy_ops_nginx_jenkins.key ansible/roles/setup_nginx_on_tls/files
cp ./ephemeral-keys/aws_dummy_ops_nginx_jenkins_proxy_client.crt ansible/roles/setup_nginx_on_tls/files
cp ./ephemeral-keys/aws_dummy_ops_nginx_jenkins_proxy_client_fullchain.crt ansible/roles/setup_nginx_on_tls/files
cp ./ephemeral-keys/aws_dummy_ops_nginx_jenkins_proxy_client.key ansible/roles/setup_nginx_on_tls/files
echo -e "$GREEN[+] Successfully copied Nginx's certs into ansible/roles/setup_nginx_on_tls/files $RESET"

cd  ephemeral-keys
find . \( -name '*aws*wazuh*.crt' -or -name '*aws*wazuh*.key' -or -name '*_ca*.crt' -or -name '*_ca*.key' \) -print | tar -czf ../ansible/roles/setup_wazuh_on_tls/files/wazuh_all_certs_files.tgz -T -
echo -e "$GREEN[+] Successfully created a wazuh_all_certs_files.tgz into ansible/roles/setup_wazuh_on_tls/files $RESET"
cd ..

echo -e "$CYAN[+] Update ansible/vars/main.yml $RESET"
JENKINS_PRIVATE_KEY="$(sed 's/^/  /' ephemeral-keys/jenkins_github)"
cat > ansible/vars/main.yml <<EOF
---
jenkins_public_ip: '$JENKINS_PUBLIC_IP'
jenkins_private_ip: '$JENKINS_PRIVATE_IP'
tomcat_public_ip: '$TOMCAT_PUBLIC_IP'
tomcat_private_ip: '$TOMCAT_PRIVATE_IP'
docker_public_ip: '$DOCKER_PUBLIC_IP'
docker_private_ip: '$DOCKER_PRIVATE_IP'
ansible_public_ip: '$ANSIBLE_PUBLIC_IP'
ansible_private_ip: '$ANSIBLE_PRIVATE_IP'
k8s_public_ip: '$K8S_PUBLIC_IP'
k8s_private_ip: '$K8S_PRIVATE_IP'
nginx_public_ip: '$NGINX_PUBLIC_IP'
nginx_private_ip: '$NGINX_PRIVATE_IP'
wazuh_dashboard_public_ip: '$WAZUH_DASHBOARD_PUBLIC_IP'
wazuh_dashboard_private_ip: '$WAZUH_DASHBOARD_PRIVATE_IP'
wazuh_indexer_public_ip: '$WAZUH_INDEXER_PUBLIC_IP'
wazuh_indexer_private_ip: '$WAZUH_INDEXER_PRIVATE_IP'
wazuh_server_public_ip: '$WAZUH_SERVER_PUBLIC_IP'
wazuh_server_private_ip: '$WAZUH_SERVER_PRIVATE_IP'

AWS_REGION: "{{ lookup('env', 'AWS_REGION') }}"
GITHUB_USERNAME: "{{ lookup('env', 'GITHUB_USERNAME') }}"
GITHUB_REPO_NAME: "{{ lookup('env', 'GITHUB_REPO_NAME') }}"
DOCKERHUB_USERNAME: "{{ lookup('env', 'DOCKERHUB_USERNAME') }}"
DOCKERHUB_REPO_NAMESPACE: "{{ lookup('env', 'DOCKERHUB_REPO_NAMESPACE') }}"
NGINX_AWS_SECRET_ID_NAME: "{{ lookup('env', 'NGINX_AWS_SECRET_ID_NAME') }}"
ANSIBLE_SSH_KEY_FILENAME: "{{ lookup('env', 'ANSIBLE_SSH_KEY_FILENAME') }}"
ANSIBLE_AWS_SECRET_ID_NAME: "{{ lookup('env', 'ANSIBLE_AWS_SECRET_ID_NAME') }}"
JENKINS_SSH_KEY_FILENAME: "{{ lookup('env', 'JENKINS_SSH_KEY_FILENAME') }}"
JENKINS_AWS_SECRET_ID_NAME: "{{ lookup('env', 'JENKINS_AWS_SECRET_ID_NAME') }}"
JENKINS_KEYSTORE_PASSPHRASE: "{{ lookup('env', 'DOCKERHUB_REPO_NAMESPACE') }}"
TOMCAT_HTTPS_KEYSTORE_PASSWORD: "{{ lookup('env', 'TOMCAT_HTTPS_KEYSTORE_PASSWORD') }}"
TOMCAT_AWS_SECRET_ID_NAME: "{{ lookup('env', 'TOMCAT_AWS_SECRET_ID_NAME') }}"
TOMCAT_DEPLOYER_CREDENTIAL_ID: "{{ lookup('env', 'TOMCAT_DEPLOYER_CREDENTIAL_ID') }}"
TOMCAT_DEPLOYER_USERNAME: "{{ lookup('env', 'TOMCAT_DEPLOYER_USERNAME') }}"
TOMCAT_DEPLOYER_PASSWORD: "{{ lookup('env', 'TOMCAT_DEPLOYER_PASSWORD') }}"
DOCKER_TOMCAT_KEYSTORE_PASSPHRASE: "{{ lookup('env', 'DOCKER_TOMCAT_KEYSTORE_PASSPHRASE') }}"
JENKINS_CREDENTIALS_ID: "{{ lookup('env', 'JENKINS_CREDENTIALS_ID') }}"
JENKINS_ADMIN_USER_USERNAME: "{{ lookup('env', 'JENKINS_ADMIN_USER_USERNAME') }}"
JENKINS_ADMIN_USER_PASSWORD: "{{ lookup('env', 'JENKINS_ADMIN_USER_PASSWORD') }}"
JENKINS_SSH_PRIVATE_KEY: |
$JENKINS_PRIVATE_KEY
EOF

echo -e "$GREEN[+] The ansible/vars/main.yml is set $RESET"
