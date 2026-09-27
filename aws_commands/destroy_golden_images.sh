#!/bin/bash
set -euo pipefail

# List all AMIs you own
AMI_IDS=$(aws ec2 describe-images --owners self --query 'Images[*].ImageId' --output text)

for AMI_ID in $AMI_IDS; do
    echo "[+] Deleting AMI $AMI_ID"

    # Get associated snapshots
    SNAPSHOTS=$(aws ec2 describe-images --image-ids "$AMI_ID" \
                --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' \
                --output text)

    # Deregister AMI
    aws ec2 deregister-image --image-id "$AMI_ID"
    echo "[+] AMI $AMI_ID deregistered."

    # Delete snapshots
    for SNAP in $SNAPSHOTS; do
        aws ec2 delete-snapshot --snapshot-id "$SNAP"
        echo "[+] Snapshot $SNAP deleted."
    done
done
