#!/bin/bash

# Lumo 2.0 max edit.
CYAN='\033[0;36m'
GREEN='\033[1;32m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "$CYAN[+] Sourcing .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

# Get ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names crook-ops-alb \
  --region eu-west-3 \
  --query "LoadBalancers[0].LoadBalancerArn" \
  --output text 2>/dev/null)

# STEP 1: Delete listeners first (listeners depend on nothing)
echo -e "$CYAN[+] Deleting listeners $RESET"
LISTENERS=$(aws elbv2 describe-listeners \
  --load-balancer-arn $ALB_ARN \
  --region eu-west-3 \
  --query "Listeners[*].ListenerArn" \
  --output text 2>/dev/null)

for LISTENER in $LISTENERS; do
  echo -e "   Deleting listener: $LISTENER"
  aws elbv2 delete-listener \
    --listener-arn $LISTENER \
    --region eu-west-3
done
echo -e "$GREEN[+] Listeners deleted $RESET"

echo -e "$CYAN[+] Sleep 5 seconds $RESET"
sleep 5

# STEP 2: Delete target groups (were dependent on listeners)
echo -e "$CYAN[+] Deleting AWS target groups $RESET"
TG_ARNS=$(aws elbv2 describe-target-groups \
  --load-balancer-arn $ALB_ARN \
  --region eu-west-3 \
  --query "TargetGroups[*].TargetGroupArn" \
  --output text 2>/dev/null)

for TG_ARN in $TG_ARNS; do
  echo -e "   Deleting AWS target group: $TG_ARN"

  TARGETS=$(aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --region eu-west-3 \
    --query "TargetHealthDescriptions[*].Target.Id" \
    --output text 2>/dev/null)

  if [[ -n "$TARGETS" ]]; then
    for TARGET in $TARGETS; do
      aws elbv2 deregister-targets \
        --target-group-arn $TG_ARN \
        --targets Id=$TARGET \
        --region eu-west-3
    done
  fi

  aws elbv2 delete-target-group --target-group-arn $TG_ARN --region eu-west-3
done
echo -e "$GREEN[+] AWS Target Groups deleted $RESET"

echo -e "$CYAN[+] Sleep 5 seconds $RESET"
sleep 5

# STEP 3: Delete the ALB (was dependent on listeners + target groups)
echo -e "$CYAN[+] Deleting AmazonLoadBalancer $RESET"
aws elbv2 delete-load-balancer \
  --load-balancer-arn $ALB_ARN \
  --region eu-west-3 2>/dev/null
echo -e "$GREEN[+] AmazonLoadBalancer deleted $RESET"

echo -e "$CYAN[+] Sleep 10 seconds $RESET"
sleep 10

# Verify
echo -e "$CYAN[+] Verifying deletion $RESET"
aws elbv2 describe-load-balancers --names crook-ops-alb --region eu-west-3 2>/dev/null
echo -e "$GREEN[+] ALB deleted successfully$RESET"
