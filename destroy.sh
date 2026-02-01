#!/bin/bash
#
# OpenClaw AWS Destroy Script
# Cleanly removes all AWS resources
#

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}"
cat << 'EOF'
  ____            _                   
 |  _ \  ___  ___| |_ _ __ ___  _   _ 
 | | | |/ _ \/ __| __| '__/ _ \| | | |
 | |_| |  __/\__ \ |_| | | (_) | |_| |
 |____/ \___||___/\__|_|  \___/ \__, |
                                |___/ 
EOF
echo -e "${NC}"

echo -e "${YELLOW}This will DESTROY all OpenClaw AWS resources!${NC}"
echo ""

# Find which deployment exists
if [ -f "terraform/simple/terraform.tfstate" ] || [ -d "terraform/simple/.terraform" ]; then
    DEPLOY_DIR="simple"
elif [ -f "terraform/full/terraform.tfstate" ] || [ -d "terraform/full/.terraform" ]; then
    DEPLOY_DIR="full"
else
    echo "No deployment found."
    exit 0
fi

echo "Found deployment: $DEPLOY_DIR"
echo ""

read -p "Are you SURE you want to destroy everything? [yes/no]: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${YELLOW}Destroying infrastructure...${NC}"

cd "terraform/$DEPLOY_DIR"

# Disable deletion protection if full deployment
if [ "$DEPLOY_DIR" == "full" ]; then
    echo "Disabling ALB deletion protection..."
    terraform apply -auto-approve \
        -var="enable_deletion_protection=false" \
        -target=aws_lb.main 2>/dev/null || true
fi

terraform destroy -auto-approve

echo ""
echo -e "${GREEN}✓ All resources destroyed${NC}"
