#!/bin/bash

set -eu

# Tag value (DOCKER, TOMCAT, NGINX, etc.)
TAG_VALUE=$1

echo "[+] Get CPUUtilization metrics for $TAG_VALUE"
# Get the Instance IDs of EC2 instances with the specified tag
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$TAG_VALUE" --query "Reservations[].Instances[].InstanceId" --output text)

# Optionally, loop through the instance IDs to get CloudWatch metrics for each
# Check "default CloudWatch metrics" for more usage
for INSTANCE_ID in $INSTANCE_IDS; do
  echo "Fetching CloudWatch metrics for instance: $INSTANCE_ID"

  # Example: Get CPU Utilization for the instance
  aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --start-time $(date -d '1 hour ago' --utc +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date --utc +%Y-%m-%dT%H:%M:%SZ) \
    --period 300 \
    --statistics Average --output table
done
