#!/bin/bash
#
# Check OpenClaw deployment status
#

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "OpenClaw AWS Status"
echo "==================="
echo ""

# Find deployment
if [ -d "terraform/simple/.terraform" ]; then
    DEPLOY_DIR="terraform/simple"
    DEPLOY_TYPE="Simple"
elif [ -d "terraform/full/.terraform" ]; then
    DEPLOY_DIR="terraform/full"
    DEPLOY_TYPE="Full"
else
    echo -e "${YELLOW}No deployment found${NC}"
    exit 0
fi

cd "$DEPLOY_DIR"

echo -e "Deployment: ${GREEN}$DEPLOY_TYPE${NC}"
echo ""

# Get outputs
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "N/A")
PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null || echo "")
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
DOMAIN=$(terraform output -raw domain_name 2>/dev/null || echo "N/A")

echo "Instance ID: $INSTANCE_ID"
echo "Domain:      $DOMAIN"

if [ -n "$PUBLIC_IP" ]; then
    echo "Public IP:   $PUBLIC_IP"
fi

if [ -n "$ALB_DNS" ]; then
    echo "ALB DNS:     $ALB_DNS"
fi

echo ""

# Check instance state
if [ "$INSTANCE_ID" != "N/A" ]; then
    STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo "unknown")
    
    if [ "$STATE" == "running" ]; then
        echo -e "EC2 State:   ${GREEN}running${NC}"
    else
        echo -e "EC2 State:   ${RED}$STATE${NC}"
    fi
fi

# Check endpoint
if [ "$DOMAIN" != "N/A" ]; then
    echo ""
    echo "Testing endpoint..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "Health:      ${GREEN}OK${NC}"
    else
        echo -e "Health:      ${RED}HTTP $HTTP_CODE${NC}"
    fi
fi
