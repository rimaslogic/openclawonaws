#!/bin/bash
#
# Connect to OpenClaw EC2 instance via SSM
#

set -e

# Find instance ID from terraform output
if [ -d "terraform/simple/.terraform" ]; then
    cd terraform/simple
elif [ -d "terraform/full/.terraform" ]; then
    cd terraform/full
else
    echo "No deployment found. Run setup.sh first."
    exit 1
fi

INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null)

if [ -z "$INSTANCE_ID" ]; then
    echo "Could not get instance ID"
    exit 1
fi

echo "Connecting to $INSTANCE_ID..."
aws ssm start-session --target "$INSTANCE_ID"
