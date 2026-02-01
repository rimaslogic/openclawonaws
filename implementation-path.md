# Implementation Path

End-to-end deployment guide from user perspective.

**Estimated time:** 2-4 hours (first time)

---

## Phase 1: Prerequisites (30 min)

### You'll need:

| Item | Where to get it | Notes |
|------|-----------------|-------|
| AWS Account | aws.amazon.com | Credit card required |
| Domain name | Any registrar | For HTTPS/webhooks |
| Anthropic API key | console.anthropic.com | For Claude access |
| Telegram bot token | @BotFather on Telegram | For Telegram channel |

### On your local machine:

```bash
# Install AWS CLI
brew install awscli   # macOS
# or
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install Terraform (for IaC)
brew install terraform
```

---

## Phase 2: AWS Account Setup (20 min)

### Step 1: Secure the root account

1. Log into AWS Console
2. Enable MFA on root account
3. Create IAM admin user (don't use root for daily work)
4. Enable MFA on admin user

### Step 2: Configure CLI

```bash
aws configure
# Enter: Access Key, Secret Key, Region (eu-central-1), Output (json)
```

### Step 3: Create KMS key (for encryption)

```bash
aws kms create-key --description "OpenClaw encryption key"
# Note the KeyId for later
```

---

## Phase 3: Infrastructure Provisioning (45 min)

### Step 1: Clone/create Terraform templates

```
infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── vpc.tf
├── ec2.tf
├── alb.tf
├── secrets.tf
└── terraform.tfvars   # Your values (gitignored)
```

### Step 2: Set your variables

```hcl
# terraform.tfvars
region            = "eu-central-1"
domain_name       = "openclaw.yourdomain.com"
kms_key_id        = "your-kms-key-id"
instance_type     = "t3.small"
```

### Step 3: Deploy infrastructure

```bash
cd infrastructure/
terraform init
terraform plan      # Review what will be created
terraform apply     # Type 'yes' to confirm
```

**Creates:**
- VPC + subnets
- EC2 instance (no access yet)
- ALB + HTTPS certificate
- Security groups
- S3 bucket for backups
- Secrets Manager entries (empty)

### Step 4: Store secrets

```bash
# Store Anthropic key
aws secretsmanager put-secret-value \
  --secret-id openclaw/anthropic-key \
  --secret-string "sk-ant-xxxxx"

# Store Telegram token
aws secretsmanager put-secret-value \
  --secret-id openclaw/telegram-token \
  --secret-string "123456:ABC-xxxxx"

# Store Gateway auth token (generate random)
aws secretsmanager put-secret-value \
  --secret-id openclaw/gateway-token \
  --secret-string "$(openssl rand -base64 32)"
```

---

## Phase 4: OpenClaw Installation (30 min)

### Step 1: Connect to instance

```bash
# Via SSM (no SSH needed)
aws ssm start-session --target i-xxxxxxxxxxxx
```

### Step 2: Install dependencies

```bash
# Update system
sudo dnf update -y

# Install Node.js 22
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo dnf install -y nodejs

# Install Docker (for sandbox)
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
```

### Step 3: Install OpenClaw

```bash
# Create app user
sudo useradd -m -s /bin/bash openclaw
sudo -u openclaw bash

# Install OpenClaw
npm install -g openclaw

# Initialize
openclaw init
```

### Step 4: Configure OpenClaw

```bash
# OpenClaw fetches secrets from Secrets Manager via IAM role
# Create config
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "gateway": {
    "bind": "loopback",
    "port": 18789,
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    }
  },
  "agents": {
    "defaults": {
      "workspace": "~/.openclaw/workspace",
      "model": {
        "primary": "anthropic/claude-opus-4-5"
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing"
    }
  }
}
EOF
```

### Step 5: Create systemd service

```bash
sudo cat > /etc/systemd/system/openclaw.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=openclaw
Environment=NODE_ENV=production
ExecStart=/usr/bin/openclaw gateway start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable openclaw
sudo systemctl start openclaw
```

---

## Phase 5: Configure Webhooks (15 min)

### Step 1: Point domain to ALB

```
# In your DNS provider:
openclaw.yourdomain.com  →  CNAME  →  alb-xxxxx.eu-central-1.elb.amazonaws.com
```

### Step 2: Set Telegram webhook

```bash
curl "https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://openclaw.yourdomain.com/telegram-webhook"
```

### Step 3: Verify

```bash
# Check OpenClaw status
openclaw status

# Send a message to your Telegram bot
# You should receive a pairing code
```

---

## Phase 6: Post-Deployment (20 min)

### Step 1: Complete pairing

```bash
# On the server
openclaw pairing list telegram
openclaw pairing approve telegram <code>
```

### Step 2: Set up backups

```bash
# Cron job for daily backup
echo "0 3 * * * /usr/local/bin/openclaw-backup.sh" | crontab -
```

### Step 3: Verify monitoring

- Check CloudWatch dashboard
- Verify alarms are configured
- Test alert notifications

---

## Quick Reference: Day-to-Day Operations

| Task | Command |
|------|---------|
| Check status | `openclaw status` |
| View logs | `openclaw logs` or CloudWatch |
| Restart gateway | `sudo systemctl restart openclaw` |
| Connect to instance | `aws ssm start-session --target i-xxx` |
| Approve pairing | `openclaw pairing approve telegram <code>` |
| Manual backup | `openclaw-backup.sh` |
| Update OpenClaw | `npm update -g openclaw && sudo systemctl restart openclaw` |

---

## Verification Checklist

After deployment, verify:

- [ ] Can connect via SSM (no SSH)
- [ ] OpenClaw service running (`systemctl status openclaw`)
- [ ] HTTPS working (visit https://openclaw.yourdomain.com/health)
- [ ] Telegram bot responds
- [ ] Pairing flow works
- [ ] CloudWatch logs appearing
- [ ] Backups running
- [ ] Alarms configured

---

## Troubleshooting

| Issue | Check |
|-------|-------|
| Can't connect to instance | IAM role has SSM permissions? |
| OpenClaw won't start | `journalctl -u openclaw -f` |
| Telegram not working | Webhook URL correct? Bot token valid? |
| HTTPS errors | ACM certificate issued? DNS propagated? |
| Secrets not loading | IAM role has Secrets Manager access? |

---

## Time Summary

| Phase | Time |
|-------|------|
| Prerequisites | 30 min |
| AWS Account Setup | 20 min |
| Infrastructure | 45 min |
| OpenClaw Install | 30 min |
| Webhooks | 15 min |
| Post-deployment | 20 min |
| **Total** | **~2.5 hours** |

*First deployment takes longer. Subsequent deployments (with IaC): ~30 minutes.*
