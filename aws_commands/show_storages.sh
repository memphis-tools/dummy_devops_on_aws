#!/bin/bash

set -eu

echo "[+] Listing AWS S3 in region $AWS_REGION"
aws s3 ls --region $AWS_REGION
