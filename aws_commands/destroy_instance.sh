#!/bin/bash
set -eu

INSTANCE_NAME=$1

echo "[+] Fetching instance IDs for instances with the Name tag '$INSTANCE_NAME'..."
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "[+] Terminating instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS &>/dev/null
else
    echo "[+] No instances found."
fi

echo "[+] Waiting for instances to terminate..."
if [ -n "$INSTANCE_IDS" ]; then
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
    echo "[+] Instances terminated."
fi

echo "[+] Done. The specified EC2 instances are terminated, AMIs remain untouched."
