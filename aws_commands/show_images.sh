#!/bin/bash
set -eu

echo "[+] Listing all AMI you own in region $AWS_REGION"

aws ec2 describe-images \
  --region $AWS_REGION \
  --owners self \
  --query "Images[].{ID:ImageId,Name:Name,CreationDate:CreationDate} | sort_by(@,&CreationDate) | reverse(@)" \
  --output table
