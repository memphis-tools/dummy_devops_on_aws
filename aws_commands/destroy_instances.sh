#!/bin/bash
set -eu

echo "[+] Fetching all instance IDs "
INSTANCE_IDS=$(aws ec2 describe-instances \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "[+] Terminating instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS &>/dev/null
else
    echo "[+] No instances found."
fi

echo "[+] Waiting for instances to terminate "
if [ -n "$INSTANCE_IDS" ]; then
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
    echo "[+] All instances terminated."
fi

echo "[+] Done. All EC2 instances are terminated, AMIs remain untouched."
