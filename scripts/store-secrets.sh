#!/bin/bash
#
# Store secrets in AWS Secrets Manager
# Run this after terraform apply if you didn't use setup.sh
#

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}Store OpenClaw Secrets${NC}"
echo ""

# Get region from tfvars or default
if [ -f "terraform/simple/terraform.tfvars" ]; then
    AWS_REGION=$(grep aws_region terraform/simple/terraform.tfvars | cut -d'"' -f2)
elif [ -f "terraform/full/terraform.tfvars" ]; then
    AWS_REGION=$(grep aws_region terraform/full/terraform.tfvars | cut -d'"' -f2)
else
    AWS_REGION="eu-central-1"
fi

echo "Region: $AWS_REGION"
echo ""

read -p "Anthropic API Key: " ANTHROPIC_KEY
read -p "Telegram Bot Token: " TELEGRAM_TOKEN
GATEWAY_TOKEN=$(openssl rand -base64 32)

echo ""
echo "Storing secrets..."

aws secretsmanager put-secret-value \
    --secret-id "openclaw/anthropic-api-key" \
    --secret-string "$ANTHROPIC_KEY" \
    --region "$AWS_REGION"

aws secretsmanager put-secret-value \
    --secret-id "openclaw/telegram-bot-token" \
    --secret-string "$TELEGRAM_TOKEN" \
    --region "$AWS_REGION"

aws secretsmanager put-secret-value \
    --secret-id "openclaw/gateway-auth-token" \
    --secret-string "$GATEWAY_TOKEN" \
    --region "$AWS_REGION"

echo ""
echo -e "${GREEN}✓ Secrets stored${NC}"
echo ""
echo "Your gateway token (save this!):"
echo "$GATEWAY_TOKEN"
