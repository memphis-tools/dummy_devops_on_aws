#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Searching ID from AMI to destroy $RESET"
# Check if AMI exists before proceeding
IMAGE_ID_TO_REMOVE=$(aws ec2 describe-images --owners self --region eu-west-3 \
  --filters "Name=name,Values=$AMI_PREFIX*" --query "Images[0].ImageId" --output text)

if [[ "$IMAGE_ID_TO_REMOVE" == "None" ]]; then
  echo "[!] Warning: No AMI found with prefix '$AMI_PREFIX'. Continuing without golden_image_id."
else
  echo "[+] Found AMI: $IMAGE_ID_TO_REMOVE"
fi

echo -e "$CYAN[+] Terraform trying to destroy $RESET"
if [[ "$IMAGE_ID_TO_REMOVE" != "None" ]]; then
  terraform destroy -auto-approve -var="aws_account_id=$TF_VAR_aws_account_id" -var="golden_image_id=$IMAGE_ID_TO_REMOVE"
fi
echo -e "$GREEN[+] Terraform destroy is ok $RESET"

echo -e "$CYAN[+] Trying to destroy the AmazonLoadBalancer $RESET"
./aws_commands/destroy_loadbalancer.sh
echo -e "$GREEN[+] AmazonLoadBalancer destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy instances $RESET"
./aws_commands/destroy_instances.sh
echo -e "$GREEN[+] Instances destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy the default AWS golden image $RESET"
./aws_commands/destroy_golden_images.sh 2>/dev/null
echo -e "$GREEN[+] Default AWS golden image destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy default AWS VPC $RESET"
./aws_commands/destroy_default_vpc.sh 2>/dev/null
echo -e "$GREEN[+] Default AWS VPC destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy default AWS Dynamodb table $RESET"
./aws_commands/destroy_dynamodb_table.sh 2>/dev/null
echo -e "$GREEN[+] Default AWS Dynamodb table destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy custom roles and policies $RESET"
./aws_commands/destroy_roles_and_attached_policies.sh 2>/dev/null
echo -e "$GREEN[+] Custom roles and policies destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy default AWS S3 storage $RESET"
./aws_commands/destroy_storage.sh 2>/dev/null
echo -e "$GREEN[+] Default AWS S3 storage destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy AWS secrets $RESET"
./aws_commands/destroy_secrets.sh 2>/dev/null
echo -e "$GREEN[+] AWS secrets destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy AWS security groups $RESET"
./aws_commands/destroy_security_groups.sh
echo -e "$GREEN[+] AWS security groups destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy AWS certificates $RESET"
./aws_commands/destroy_aws_certificates.sh
echo -e "$GREEN[+] AWS certificates destroyed $RESET"

echo -e "$CYAN[+] Trying to destroy ephemeral keys, certs $RESET"
rm ./ephemeral-keys/* 2>/dev/null
touch ./ephemeral-keys/.gitkeep
echo -e "$GREEN[+] self signed certs destroyed $RESET"

echo -e "$CYAN[+] Purge known_hosts $RESET"
ssh-keygen -R aws-dummy-ops-ansible.lab 2>/dev/null
ssh-keygen -R aws-dummy-ops-docker.lab 2>/dev/null
ssh-keygen -R aws-dummy-ops-tomcat.lab 2>/dev/null
ssh-keygen -R aws-dummy-ops-jenkins.lab 2>/dev/null
ssh-keygen -R aws-dummy-ops-nginx.lab 2>/dev/null
ssh-keygen -R aws-dummy-ops-wazuh-dashboard.lab 2>/dev/null
ssh-keygen -R aws-dummy-ops-wazuh-indexer.lab 2>/dev/null
ssh-keygen -R aws-dummy-ops-wazuh-server.lab 2>/dev/null
ssh-keygen -R aws-dummy-ops-k8s.lab 2>/dev/null
sed -e '/^aws-dummy-ops/d' -i ~/.ssh/known_hosts
echo -e "$GREEN[+] Purge done $RESET"

echo -e "$CYAN[+] Purge local terraform and certificate files $RESET"
rm ./terraform/tfplan.out 2>/dev/null
rm ./terraform/.terraform.lock.hcl 2>/dev/null
rm -rf ./terraform/.terraform 2>/dev/null
rm ./ansible/.ansible.secret 2>/dev/null
rm ./ansible/.keystores-passphrase 2>/dev/null
find . -type f -iname *.crt -exec rm {} \;
find . -type f -iname *.key -exec rm {} \;
find . -type f -iname *.pem -exec rm {} \;
find . -type f -iname *.keystore -exec rm {} \;
find . -type f -iname *.truststore -exec rm {} \;
echo -e "$GREEN[+] Purge done $RESET"
