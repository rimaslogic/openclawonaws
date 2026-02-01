# OpenClaw AWS - Simple Deployment

Single-user deployment optimized for cost and simplicity.

## Cost: ~$18-25/month

| Component | Cost |
|-----------|------|
| EC2 t3.micro | $7.59 |
| EBS 20GB | $1.60 |
| Elastic IP | $3.65 |
| Secrets Manager | $1.20 |
| KMS | $1.00 |
| **Total** | **~$15-18** |

## Architecture

```
Internet → EC2 (Elastic IP)
              ↓
           Caddy (TLS)
              ↓
           OpenClaw
              ↓
        Secrets Manager
```

## Features

- ✅ Automatic HTTPS via Caddy + Let's Encrypt
- ✅ Encrypted EBS storage
- ✅ Secrets in AWS Secrets Manager
- ✅ SSM Session Manager (no SSH required)
- ✅ IMDSv2 required

## What's NOT included (vs Full)

- ❌ No ALB (Caddy handles TLS directly)
- ❌ No NAT Gateway
- ❌ No WAF
- ❌ No VPC Endpoints
- ❌ No private subnet

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your domain

terraform init
terraform plan
terraform apply
```

## Post-Deployment

1. **Point DNS** to the Elastic IP (shown in output)
2. **Store secrets:**
   ```bash
   aws secretsmanager put-secret-value \
     --secret-id openclaw/anthropic-api-key \
     --secret-string "sk-ant-xxx"
   
   aws secretsmanager put-secret-value \
     --secret-id openclaw/telegram-bot-token \
     --secret-string "123456:ABC"
   
   aws secretsmanager put-secret-value \
     --secret-id openclaw/gateway-auth-token \
     --secret-string "$(openssl rand -base64 32)"
   ```
3. **Start services:**
   ```bash
   aws ssm start-session --target <instance-id>
   sudo systemctl start caddy
   sudo systemctl start openclaw
   ```
4. **Set Telegram webhook:**
   ```bash
   curl "https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://your-domain/telegram-webhook"
   ```

## When to use Full instead

Choose the **Full** deployment if you need:
- Multiple users
- WAF protection
- High availability
- Compliance requirements
- Network isolation
