#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'
WHITE='\033[1;97m'

source .env

# cat > ./packer/variables.auto.pkrvars.hcl <<EOL
# ami_build_name         = "devops-machine"
# ami_instance_type      = "t2.micro"
# ami_owner_id           = ["$AMI_OWNER_ID"]
# ami_prefix             = "$AMI_PREFIX"
# ami_region             = "$AWS_REGION"
# ami_ssh_key_pair_name  = "$TF_VAR_aws_keypair_name"
# ami_ssh_username       = "admin"
# ami_software_full_name = "debian-12-amd64-*"
# ami_software_name      = "debian"
# ssh_pubkey_path        = "$TF_VAR_ssh_pubkey_path"
# EOL


packer init ./packer

packer fmt ./packer

packer validate ./packer

AMI_ID=$(packer build -machine-readable ./packer/aws-debian.pkr.hcl \
   | grep '^.*artifact,0,id,' | tail -1 | cut -d':' -f2)

AMI_NAME=$(aws ec2 describe-images --image-ids $AMI_ID --query 'Images[0].Name' --output text)

# Only output
echo $AMI_ID
