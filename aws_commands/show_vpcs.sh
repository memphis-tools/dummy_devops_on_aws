#!/bin/bash

set -eu

echo "[+] Listing AWS VPC in region $AWS_REGION"
aws ec2 describe-vpcs --region $AWS_REGION --output table
