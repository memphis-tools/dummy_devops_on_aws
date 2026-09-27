#!/bin/bash
set -eu

# Create a default VPC for your region
aws ec2 create-default-vpc --region $AWS_REGION

# Check the VPC creation
aws ec2 describe-vpcs --region $AWS_REGION --filters Name=isDefault,Values=true
