#!/bin/bash
#
# Set Telegram webhook
#

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./scripts/set-webhook.sh <bot-token> <domain>"
    echo "Example: ./scripts/set-webhook.sh 123456:ABC openclaw.example.com"
    exit 1
fi

BOT_TOKEN=$1
DOMAIN=$2

echo "Setting webhook to: https://$DOMAIN/telegram-webhook"
echo ""

curl -s "https://api.telegram.org/bot$BOT_TOKEN/setWebhook?url=https://$DOMAIN/telegram-webhook" | jq .

echo ""
echo "Webhook info:"
curl -s "https://api.telegram.org/bot$BOT_TOKEN/getWebhookInfo" | jq .
