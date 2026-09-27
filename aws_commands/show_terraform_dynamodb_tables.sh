#!/bin/bash
set -eu

# Check the Dynamodb table creation:
aws dynamodb list-tables --region $AWS_REGION
