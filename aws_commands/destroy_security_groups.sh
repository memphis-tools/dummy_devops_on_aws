#!/bin/bash

set -u

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

echo -e "$CYAN[+] Finding AWS security groups with 'security-group' in name $RESET"
# Get all matching security group IDs
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*security-group*" \
  --region eu-west-3 \
  --query "SecurityGroups[*].GroupId" --output text 2>/dev/null)

for SG_ID in $SG_IDS; do
  echo "   Deleting: $SG_ID"

  # Delete any ENIs attached first
  ENI_IDS=$(aws ec2 describe-network-interfaces \
    --filters "Name=group-id,Values=$SG_ID" \
    --query "NetworkInterfaces[*].NetworkInterfaceId" --output text)

  for ENI in $ENI_IDS; do
    aws ec2 delete-network-interface --network-interface-id $ENI --region eu-west-3 2>/dev/null
  done

  # Delete the security group
  aws ec2 delete-security-group --group-id $SG_ID --region eu-west-3
done
echo -e "$GREEN[+] AWS Security Groups removed $RESET"
