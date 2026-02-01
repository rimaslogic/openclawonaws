#!/bin/bash
#
# OpenClaw AWS Setup - Interactive Wizard
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║              OpenClaw on AWS - Setup Wizard                   ║"
echo "║                                                               ║"
echo "║  This wizard will deploy OpenClaw to your AWS account.       ║"
echo "║  Estimated cost: ~\$10/month                                   ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

#═══════════════════════════════════════════════════════════════════════
# STEP 1: Check Prerequisites
#═══════════════════════════════════════════════════════════════════════
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 1/7: Checking Prerequisites${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Checking if required tools are installed..."
echo ""

# Check Terraform
echo -n "  Terraform: "
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || terraform version | head -1)
    echo -e "${GREEN}✓ Installed ($TF_VERSION)${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
    echo ""
    echo -e "${RED}Terraform is required. Install it:${NC}"
    echo "  macOS:  brew install terraform"
    echo "  Ubuntu: apt install terraform"
    echo "  Other:  https://terraform.io/downloads"
    exit 1
fi

# Check AWS CLI
echo -n "  AWS CLI:   "
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    echo -e "${GREEN}✓ Installed ($AWS_VERSION)${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
    echo ""
    echo -e "${RED}AWS CLI is required. Install it:${NC}"
    echo "  macOS:  brew install awscli"
    echo "  Ubuntu: apt install awscli"
    echo "  Other:  https://aws.amazon.com/cli/"
    exit 1
fi

echo ""
echo -e "${GREEN}All prerequisites met!${NC}"
echo ""

#═══════════════════════════════════════════════════════════════════════
# STEP 2: Verify AWS Account Access
#═══════════════════════════════════════════════════════════════════════
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 2/7: Verifying AWS Account Access${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Checking your AWS credentials..."
echo ""

# Try to get current identity
set +e
AWS_IDENTITY=$(aws sts get-caller-identity 2>&1)
AWS_CHECK=$?
set -e

if [ $AWS_CHECK -ne 0 ]; then
    echo -e "${RED}✗ Cannot access AWS account${NC}"
    echo ""
    echo "Error: $AWS_IDENTITY"
    echo ""
    echo "Please configure AWS credentials:"
    echo "  aws configure"
    exit 1
fi

AWS_ACCOUNT_ID=$(echo "$AWS_IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
AWS_USER_ARN=$(echo "$AWS_IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
AWS_USER=$(echo "$AWS_USER_ARN" | rev | cut -d'/' -f1 | rev)

echo -e "  Current Account:  ${GREEN}$AWS_ACCOUNT_ID${NC}"
echo -e "  Current User:     ${GREEN}$AWS_USER${NC}"
echo ""

echo "Where do you want to deploy OpenClaw?"
echo ""
echo "  1) Use current account ($AWS_ACCOUNT_ID)"
echo "  2) Use a different AWS profile"
echo "  3) Assume role in a different account"
echo ""
read -p "Choose [1-3, default 1]: " ACCOUNT_CHOICE

#-----------------------------------------------------------------------
# Option 2: Use a different AWS profile
#-----------------------------------------------------------------------
if [ "$ACCOUNT_CHOICE" = "2" ]; then
    echo ""
    echo -e "${BLUE}AWS Profile Selection${NC}"
    echo ""
    
    # List available profiles
    echo "Available profiles:"
    PROFILES=""
    if [ -f ~/.aws/credentials ]; then
        PROFILES=$(grep '^\[' ~/.aws/credentials | tr -d '[]')
    fi
    if [ -f ~/.aws/config ]; then
        CONFIG_PROFILES=$(grep '^\[profile ' ~/.aws/config | sed 's/\[profile //' | tr -d ']')
        PROFILES="$PROFILES $CONFIG_PROFILES"
    fi
    
    # Remove duplicates and print
    echo "$PROFILES" | tr ' ' '\n' | sort -u | while read -r profile; do
        if [ -n "$profile" ]; then
            echo "  • $profile"
        fi
    done
    echo ""
    
    read -p "Enter profile name: " AWS_PROFILE_NAME
    
    if [ -z "$AWS_PROFILE_NAME" ]; then
        echo -e "${RED}Error: Profile name is required${NC}"
        exit 1
    fi
    
    export AWS_PROFILE="$AWS_PROFILE_NAME"
    
    echo ""
    echo "Verifying profile '$AWS_PROFILE_NAME'..."
    echo ""
    
    # Try to get identity with the profile
    set +e
    NEW_IDENTITY=$(aws sts get-caller-identity 2>&1)
    IDENTITY_RESULT=$?
    set -e
    
    # If failed, check if MFA might be needed
    if [ $IDENTITY_RESULT -ne 0 ]; then
        echo -e "${YELLOW}Profile verification failed.${NC}"
        echo "Error: $NEW_IDENTITY"
        echo ""
        
        # Check if it's an MFA-related error
        if echo "$NEW_IDENTITY" | grep -qiE "mfa|token|session|accessdenied"; then
            echo "This might require MFA. Do you want to authenticate with MFA? [y/N]: "
            read -p "" USE_MFA
            
            if [[ $USE_MFA =~ ^[Yy]$ ]]; then
                echo ""
                # Need to get MFA device - use default profile temporarily
                unset AWS_PROFILE
                
                echo "Detecting MFA devices for your user..."
                set +e
                MFA_DEVICES=$(aws iam list-mfa-devices --query 'MFADevices[*].SerialNumber' --output text 2>/dev/null)
                set -e
                
                if [ -n "$MFA_DEVICES" ] && [ "$MFA_DEVICES" != "None" ]; then
                    echo "Found MFA device(s):"
                    echo "$MFA_DEVICES" | tr '\t' '\n' | while read -r device; do
                        [ -n "$device" ] && echo "  • $device"
                    done
                    echo ""
                    
                    # Use first device if only one
                    FIRST_DEVICE=$(echo "$MFA_DEVICES" | awk '{print $1}')
                    read -p "MFA device ARN [$FIRST_DEVICE]: " MFA_SERIAL
                    MFA_SERIAL="${MFA_SERIAL:-$FIRST_DEVICE}"
                else
                    echo "Could not auto-detect MFA device."
                    echo "Format: arn:aws:iam::ACCOUNT_ID:mfa/USERNAME"
                    read -p "MFA device ARN: " MFA_SERIAL
                fi
                
                if [ -z "$MFA_SERIAL" ]; then
                    echo -e "${RED}Error: MFA device ARN is required${NC}"
                    exit 1
                fi
                
                read -p "Enter MFA code (6 digits): " MFA_CODE
                
                if [ -z "$MFA_CODE" ]; then
                    echo -e "${RED}Error: MFA code is required${NC}"
                    exit 1
                fi
                
                echo ""
                echo "Getting session credentials with MFA..."
                
                set +e
                SESSION_CREDS=$(aws sts get-session-token \
                    --serial-number "$MFA_SERIAL" \
                    --token-code "$MFA_CODE" \
                    --duration-seconds 3600 2>&1)
                SESSION_RESULT=$?
                set -e
                
                if [ $SESSION_RESULT -ne 0 ]; then
                    echo -e "${RED}✗ Failed to get session token${NC}"
                    echo "Error: $SESSION_CREDS"
                    exit 1
                fi
                
                # Export the session credentials
                export AWS_ACCESS_KEY_ID=$(echo "$SESSION_CREDS" | grep -o '"AccessKeyId": "[^"]*"' | cut -d'"' -f4)
                export AWS_SECRET_ACCESS_KEY=$(echo "$SESSION_CREDS" | grep -o '"SecretAccessKey": "[^"]*"' | cut -d'"' -f4)
                export AWS_SESSION_TOKEN=$(echo "$SESSION_CREDS" | grep -o '"SessionToken": "[^"]*"' | cut -d'"' -f4)
                unset AWS_PROFILE
                
                EXPIRATION=$(echo "$SESSION_CREDS" | grep -o '"Expiration": "[^"]*"' | cut -d'"' -f4)
                echo -e "${GREEN}✓ MFA authentication successful${NC}"
                echo -e "${YELLOW}Session expires: $EXPIRATION${NC}"
                echo ""
                
                # Re-verify
                NEW_IDENTITY=$(aws sts get-caller-identity)
            else
                echo -e "${RED}Aborted.${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Cannot use this profile. Please check configuration.${NC}"
            exit 1
        fi
    fi
    
    # Parse the identity
    AWS_ACCOUNT_ID=$(echo "$NEW_IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
    AWS_USER_ARN=$(echo "$NEW_IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
    AWS_USER=$(echo "$AWS_USER_ARN" | rev | cut -d'/' -f1 | rev)
    
    echo -e "${GREEN}✓ Profile verified${NC}"
    echo -e "  Account:  ${GREEN}$AWS_ACCOUNT_ID${NC}"
    echo -e "  User:     ${GREEN}$AWS_USER${NC}"
    echo ""

#-----------------------------------------------------------------------
# Option 3: Assume role in a different account
#-----------------------------------------------------------------------
elif [ "$ACCOUNT_CHOICE" = "3" ]; then
    echo ""
    echo -e "${BLUE}Assume Role Configuration${NC}"
    echo ""
    echo "Enter the Role ARN to assume."
    echo "Format: arn:aws:iam::TARGET_ACCOUNT_ID:role/ROLE_NAME"
    echo ""
    read -p "Role ARN: " ROLE_ARN
    
    if [ -z "$ROLE_ARN" ]; then
        echo -e "${RED}Error: Role ARN is required${NC}"
        exit 1
    fi
    
    echo ""
    read -p "External ID (leave empty if not required): " EXTERNAL_ID
    
    echo ""
    read -p "Does this role require MFA? [y/N]: " MFA_REQUIRED
    
    MFA_ARGS=""
    
    if [[ $MFA_REQUIRED =~ ^[Yy]$ ]]; then
        echo ""
        echo "Detecting MFA devices..."
        
        set +e
        MFA_DEVICES=$(aws iam list-mfa-devices --query 'MFADevices[*].SerialNumber' --output text 2>/dev/null)
        set -e
        
        if [ -n "$MFA_DEVICES" ] && [ "$MFA_DEVICES" != "None" ]; then
            echo "Found MFA device(s):"
            echo "$MFA_DEVICES" | tr '\t' '\n' | while read -r device; do
                [ -n "$device" ] && echo "  • $device"
            done
            echo ""
            
            FIRST_DEVICE=$(echo "$MFA_DEVICES" | awk '{print $1}')
            read -p "MFA device ARN [$FIRST_DEVICE]: " MFA_SERIAL
            MFA_SERIAL="${MFA_SERIAL:-$FIRST_DEVICE}"
        else
            echo "Could not auto-detect MFA device."
            echo "Format: arn:aws:iam::ACCOUNT_ID:mfa/USERNAME"
            read -p "MFA device ARN: " MFA_SERIAL
        fi
        
        if [ -z "$MFA_SERIAL" ]; then
            echo -e "${RED}Error: MFA device ARN is required${NC}"
            exit 1
        fi
        
        read -p "Enter MFA code (6 digits): " MFA_CODE
        
        if [ -z "$MFA_CODE" ]; then
            echo -e "${RED}Error: MFA code is required${NC}"
            exit 1
        fi
        
        MFA_ARGS="--serial-number $MFA_SERIAL --token-code $MFA_CODE"
    fi
    
    SESSION_NAME="openclaw-setup-$(date +%s)"
    
    echo ""
    echo "Assuming role..."
    
    # Build command
    ASSUME_CMD="aws sts assume-role --role-arn $ROLE_ARN --role-session-name $SESSION_NAME"
    [ -n "$EXTERNAL_ID" ] && ASSUME_CMD="$ASSUME_CMD --external-id $EXTERNAL_ID"
    [ -n "$MFA_ARGS" ] && ASSUME_CMD="$ASSUME_CMD $MFA_ARGS"
    
    set +e
    ASSUMED_ROLE=$(eval $ASSUME_CMD 2>&1)
    ASSUME_RESULT=$?
    set -e
    
    if [ $ASSUME_RESULT -ne 0 ]; then
        echo -e "${RED}✗ Failed to assume role${NC}"
        echo ""
        echo "Error: $ASSUMED_ROLE"
        echo ""
        echo "Common issues:"
        echo "  • Role ARN is incorrect"
        echo "  • Trust policy doesn't allow your account/user"
        echo "  • External ID is required but not provided"
        echo "  • MFA is required but not provided or incorrect"
        exit 1
    fi
    
    # Extract and export credentials
    export AWS_ACCESS_KEY_ID=$(echo "$ASSUMED_ROLE" | grep -o '"AccessKeyId": "[^"]*"' | cut -d'"' -f4)
    export AWS_SECRET_ACCESS_KEY=$(echo "$ASSUMED_ROLE" | grep -o '"SecretAccessKey": "[^"]*"' | cut -d'"' -f4)
    export AWS_SESSION_TOKEN=$(echo "$ASSUMED_ROLE" | grep -o '"SessionToken": "[^"]*"' | cut -d'"' -f4)
    
    # Get new identity
    NEW_IDENTITY=$(aws sts get-caller-identity)
    AWS_ACCOUNT_ID=$(echo "$NEW_IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
    AWS_USER_ARN=$(echo "$NEW_IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
    AWS_USER=$(echo "$AWS_USER_ARN" | rev | cut -d'/' -f1 | rev)
    
    EXPIRATION=$(echo "$ASSUMED_ROLE" | grep -o '"Expiration": "[^"]*"' | cut -d'"' -f4)
    
    echo -e "${GREEN}✓ Role assumed successfully${NC}"
    echo -e "  Account:  ${GREEN}$AWS_ACCOUNT_ID${NC}"
    echo -e "  Role:     ${GREEN}$AWS_USER${NC}"
    echo -e "${YELLOW}Session expires: $EXPIRATION${NC}"
    echo ""
fi

echo -e "${YELLOW}⚠️  Resources will be created in account $AWS_ACCOUNT_ID${NC}"
echo ""
echo "Resources to be created:"
echo "  • 1 VPC with public subnet"
echo "  • 1 EC2 instance (t3.micro)"
echo "  • 1 Security group"
echo "  • 1 IAM role for EC2"
echo ""
read -p "Do you want to proceed? [y/N]: " CONFIRM_ACCOUNT

if [[ ! $CONFIRM_ACCOUNT =~ ^[Yy]$ ]]; then
    echo ""
    echo "Aborted. No changes were made."
    exit 0
fi

echo ""

#═══════════════════════════════════════════════════════════════════════
# STEP 3: Select AWS Region
#═══════════════════════════════════════════════════════════════════════
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 3/7: Select AWS Region${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Choose where to deploy OpenClaw:"
echo ""
echo "  1) eu-central-1  (Frankfurt, Europe)"
echo "  2) us-east-1     (N. Virginia, US East)"
echo "  3) us-west-2     (Oregon, US West)"
echo ""
read -p "Select region [1-3, default 1]: " REGION_CHOICE

case $REGION_CHOICE in
    2) AWS_REGION="us-east-1" ;;
    3) AWS_REGION="us-west-2" ;;
    *) AWS_REGION="eu-central-1" ;;
esac

echo ""
echo -e "Selected region: ${GREEN}$AWS_REGION${NC}"
echo ""

#═══════════════════════════════════════════════════════════════════════
# STEP 4: Check for Existing Resources
#═══════════════════════════════════════════════════════════════════════
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 4/7: Checking for Existing Resources${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Scanning for existing OpenClaw resources in $AWS_REGION..."
echo ""

EXISTING_ISSUES=()

# Check for existing VPC with openclaw name
echo -n "  Checking VPCs... "
set +e
EXISTING_VPC=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=*openclaw*" \
    --region "$AWS_REGION" \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null)
set -e

if [ -n "$EXISTING_VPC" ] && [ "$EXISTING_VPC" != "None" ]; then
    echo -e "${YELLOW}Found: $EXISTING_VPC${NC}"
    EXISTING_ISSUES+=("VPC: $EXISTING_VPC")
else
    echo -e "${GREEN}None found${NC}"
fi

# Check for existing EC2 instances
echo -n "  Checking EC2 instances... "
set +e
EXISTING_EC2=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=*openclaw*" "Name=instance-state-name,Values=running,stopped" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null)
set -e

if [ -n "$EXISTING_EC2" ] && [ "$EXISTING_EC2" != "None" ]; then
    echo -e "${YELLOW}Found: $EXISTING_EC2${NC}"
    EXISTING_ISSUES+=("EC2: $EXISTING_EC2")
else
    echo -e "${GREEN}None found${NC}"
fi

# Check for existing IAM role
echo -n "  Checking IAM roles... "
set +e
EXISTING_ROLE=$(aws iam get-role --role-name openclaw-ec2-role --query 'Role.RoleName' --output text 2>/dev/null)
set -e

if [ -n "$EXISTING_ROLE" ] && [ "$EXISTING_ROLE" != "None" ]; then
    echo -e "${YELLOW}Found: $EXISTING_ROLE${NC}"
    EXISTING_ISSUES+=("IAM Role: $EXISTING_ROLE")
else
    echo -e "${GREEN}None found${NC}"
fi

# Check for existing Terraform state
echo -n "  Checking local Terraform state... "
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/terraform/terraform.tfstate" ]; then
    echo -e "${YELLOW}Found existing state file${NC}"
    EXISTING_ISSUES+=("Local Terraform state")
else
    echo -e "${GREEN}None found${NC}"
fi

echo ""

if [ ${#EXISTING_ISSUES[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  WARNING: Existing OpenClaw resources detected:${NC}"
    echo ""
    for issue in "${EXISTING_ISSUES[@]}"; do
        echo "  • $issue"
    done
    echo ""
    echo "Options:"
    echo "  1) Continue anyway (may update/replace existing resources)"
    echo "  2) Abort (make no changes)"
    echo ""
    read -p "Choose [1-2]: " EXISTING_CHOICE
    
    if [ "$EXISTING_CHOICE" != "1" ]; then
        echo ""
        echo "Aborted. No changes were made."
        echo ""
        echo "To destroy existing resources first, run:"
        echo "  cd terraform && terraform destroy"
        exit 0
    fi
    echo ""
else
    echo -e "${GREEN}No existing OpenClaw resources found. Safe to proceed.${NC}"
    echo ""
fi

#═══════════════════════════════════════════════════════════════════════
# STEP 5: Collect Credentials
#═══════════════════════════════════════════════════════════════════════
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 5/7: Enter Your API Credentials${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Telegram Token
echo -e "${BLUE}Telegram Bot Token${NC}"
echo "Create a bot via @BotFather on Telegram and paste the token here."
echo "Format: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
echo ""
read -p "Token: " TELEGRAM_TOKEN

if [ -z "$TELEGRAM_TOKEN" ]; then
    echo -e "${RED}Error: Telegram token is required${NC}"
    exit 1
fi

echo ""

# Anthropic Key
echo -e "${BLUE}Anthropic API Key${NC}"
echo "Get your API key from: https://console.anthropic.com/settings/keys"
echo "Format: sk-ant-..."
echo ""
read -p "Key: " ANTHROPIC_KEY

if [ -z "$ANTHROPIC_KEY" ]; then
    echo -e "${RED}Error: Anthropic API key is required${NC}"
    exit 1
fi

echo ""

#═══════════════════════════════════════════════════════════════════════
# STEP 6: Deploy Infrastructure
#═══════════════════════════════════════════════════════════════════════
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 6/7: Deploying Infrastructure${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Deploying to AWS account $AWS_ACCOUNT_ID in $AWS_REGION..."
echo "This typically takes 2-3 minutes."
echo ""

cd "$SCRIPT_DIR/terraform"

# Create tfvars
cat > terraform.tfvars << EOF
aws_region = "$AWS_REGION"
EOF

# Initialize Terraform
echo "  Initializing Terraform..."
terraform init -input=false > /dev/null 2>&1

# Plan
echo "  Planning deployment..."
terraform plan -input=false -out=tfplan > /dev/null 2>&1

# Apply
echo "  Creating AWS resources..."
terraform apply -auto-approve tfplan

# Get instance ID
INSTANCE_ID=$(terraform output -raw instance_id)

echo ""
echo -e "${GREEN}✓ Infrastructure deployed successfully!${NC}"
echo -e "  Instance ID: ${GREEN}$INSTANCE_ID${NC}"
echo ""

#═══════════════════════════════════════════════════════════════════════
# STEP 7: Configure OpenClaw
#═══════════════════════════════════════════════════════════════════════
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 7/7: Configuring OpenClaw${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "  Waiting for EC2 instance to be ready..."
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
echo -e "  ${GREEN}✓ Instance is running${NC}"

echo "  Waiting for OpenClaw to install (60 seconds)..."
sleep 60
echo -e "  ${GREEN}✓ Installation complete${NC}"

echo "  Configuring OpenClaw with your credentials..."

# Create config (base64 to handle special chars)
CONFIG_JSON=$(cat << EOF
{
  "model": {
    "provider": "anthropic",
    "model": "claude-sonnet-4-20250514"
  },
  "anthropicApiKey": "$ANTHROPIC_KEY",
  "channels": {
    "telegram": {
      "botToken": "$TELEGRAM_TOKEN"
    }
  }
}
EOF
)

CONFIG_B64=$(echo "$CONFIG_JSON" | base64 -w0 2>/dev/null || echo "$CONFIG_JSON" | base64)

# Send configuration via SSM
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "{\"commands\":[
        \"mkdir -p /home/openclaw/.openclaw\",
        \"echo '$CONFIG_B64' | base64 -d > /home/openclaw/.openclaw/config.json\",
        \"chown -R openclaw:openclaw /home/openclaw/.openclaw\",
        \"systemctl restart openclaw\"
    ]}" \
    --region "$AWS_REGION" \
    --query 'Command.CommandId' \
    --output text)

echo "  Applying configuration..."
sleep 15

# Check command status
set +e
STATUS=$(aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Status' \
    --output text 2>/dev/null)
set -e

if [ "$STATUS" = "Success" ]; then
    echo -e "  ${GREEN}✓ OpenClaw configured and started${NC}"
else
    echo -e "  ${YELLOW}⚠ Configuration in progress (Status: $STATUS)${NC}"
fi

echo ""

#═══════════════════════════════════════════════════════════════════════
# COMPLETE
#═══════════════════════════════════════════════════════════════════════
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║                    SETUP COMPLETE! 🎉                         ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Your OpenClaw instance is ready!"
echo ""
echo -e "  ${BLUE}Instance ID:${NC}  $INSTANCE_ID"
echo -e "  ${BLUE}Region:${NC}       $AWS_REGION"
echo -e "  ${BLUE}Account:${NC}      $AWS_ACCOUNT_ID"
echo ""
echo -e "${GREEN}→ Message your Telegram bot now!${NC}"
echo ""
echo "Useful commands:"
echo ""
echo "  # Connect to instance"
echo "  aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION"
echo ""
echo "  # View logs"
echo "  sudo journalctl -u openclaw -f"
echo ""
echo "  # Restart OpenClaw"
echo "  sudo systemctl restart openclaw"
echo ""
echo "  # Destroy everything"
echo "  cd $(pwd) && terraform destroy"
echo ""
