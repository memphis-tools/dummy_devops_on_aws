#!/bin/bash

set -eu

echo "[+] Listing AWS Security Groups in region $AWS_REGION"
aws ec2 describe-security-groups --region $AWS_REGION --filters Name=group-name,Values=jenkins-security-group
