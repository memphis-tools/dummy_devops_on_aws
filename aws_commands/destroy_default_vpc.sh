#!/bin/bash
set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

# Get default VPC ID
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --filters Name=isDefault,Values=true \
  --query "Vpcs[0].VpcId" \
  --output text)

if [[ "$DEFAULT_VPC_ID" == "None" ]]; then
  echo -e "$GREEN[+] No default VPC found in $AWS_REGION $RESET"
  exit 0
fi

echo -e "$CYAN[+] Deleting AWS default VPC: $DEFAULT_VPC_ID $RESET"

# 1. Detach and delete Internet Gateways
IGW_IDS=$(aws ec2 describe-internet-gateways \
  --region "$AWS_REGION" \
  --filters Name=attachment.vpc-id,Values="$DEFAULT_VPC_ID" \
  --query "InternetGateways[].InternetGatewayId" \
  --output text)

for igw in $IGW_IDS; do
  echo -e "$CYAN[+] Detaching and deleting IGW: $igw $RESET"
  aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$DEFAULT_VPC_ID" --region "$AWS_REGION"
  aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region "$AWS_REGION"
done
echo -e "$GREEN[+] AWS Internet Gateways removed $RESET"

# 2. Delete Subnets
SUBNET_IDS=$(aws ec2 describe-subnets \
  --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$DEFAULT_VPC_ID" \
  --query "Subnets[].SubnetId" \
  --output text)

for subnet in $SUBNET_IDS; do
  echo "[+] Deleting subnet: $subnet"
  aws ec2 delete-subnet --subnet-id "$subnet" --region "$AWS_REGION"
done
echo -e "$GREEN[+] AWS subnets removed $RESET"

# 3. Delete Route Tables (skip main)
RTB_IDS=$(aws ec2 describe-route-tables \
  --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$DEFAULT_VPC_ID" \
  --query "RouteTables[].RouteTableId" \
  --output text)

for rtb in $RTB_IDS; do
  MAIN=$(aws ec2 describe-route-tables \
    --region "$AWS_REGION" \
    --route-table-ids "$rtb" \
    --query "RouteTables[0].Associations[?Main].Main" \
    --output text || true)

  if [[ "$MAIN" == "True" ]]; then
    echo -e "$GREEN[+] Skipping main route table: $rtb $RESET"
  else
    echo -e "$CYAN[+] Deleting route table: $rtb $RESET"
    aws ec2 delete-route-table --route-table-id "$rtb" --region "$AWS_REGION"
  fi
done

# 4. Delete Security Groups (skip default)
SG_IDS=$(aws ec2 describe-security-groups \
  --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$DEFAULT_VPC_ID" \
  --query "SecurityGroups[].GroupId" \
  --output text)

for sg in $SG_IDS; do
  NAME=$(aws ec2 describe-security-groups \
    --region "$AWS_REGION" \
    --group-ids "$sg" \
    --query "SecurityGroups[0].GroupName" \
    --output text)

  if [[ "$NAME" == "default" ]]; then
    echo -e "$GREEN[+] Skipping default security group: $sg $RESET"
  else
    echo -e "$GREEN[+] Deleting security group: $sg $RESET"
    aws ec2 delete-security-group --group-id "$sg" --region "$AWS_REGION"
  fi
done

# 5. Delete Network ACLs (skip default)
ACL_IDS=$(aws ec2 describe-network-acls \
  --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$DEFAULT_VPC_ID" \
  --query "NetworkAcls[].NetworkAclId" \
  --output text)

for acl in $ACL_IDS; do
  IS_DEFAULT=$(aws ec2 describe-network-acls \
    --region "$AWS_REGION" \
    --network-acl-ids "$acl" \
    --query "NetworkAcls[0].IsDefault" \
    --output text)

  if [[ "$IS_DEFAULT" == "True" ]]; then
    echo -e "$GREEN[+] Skipping default NACL: $acl $RESET"
  else
    echo -e "$GREEN[+] Deleting NACL: $acl $RESET"
    aws ec2 delete-network-acl --network-acl-id "$acl" --region "$AWS_REGION"
  fi
done

# 6. Delete the VPC
echo -e "$GREEN[+] Deleting VPC: $DEFAULT_VPC_ID $RESET"
aws ec2 delete-vpc --vpc-id "$DEFAULT_VPC_ID" --region "$AWS_REGION"

echo -e "$GREEN[+] Default VPC $DEFAULT_VPC_ID deleted successfully. $RESET"
