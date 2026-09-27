#!/bin/bash
set -eu

aws s3api create-bucket \
    --bucket dummy-devops-terraform-state-bucket \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION
