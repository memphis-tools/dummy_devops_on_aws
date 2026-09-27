#!/bin/bash
set -eu

# Create a default VPC for your region:
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION

# Check the Dynamodb table creation:
aws dynamodb list-tables --region eu-west-3
