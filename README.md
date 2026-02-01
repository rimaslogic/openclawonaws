# OpenClaw on AWS

Deploy [OpenClaw](https://github.com/openclaw/openclaw) AI assistant on AWS.

## ⚡ Quick Start (5 minutes)

```bash
git clone https://github.com/rimaslogic/openclawonaws.git
cd openclawonaws
./setup.sh
```

That's it! The wizard handles everything:
- ✅ Deploys infrastructure
- ✅ Stores your API keys securely
- ✅ Starts OpenClaw
- ✅ Configures Telegram webhook

---

## What You Need

1. **AWS account** with admin access
2. **Domain name** pointed to AWS (can do after deploy)
3. **Anthropic API key** from [console.anthropic.com](https://console.anthropic.com)
4. **Telegram bot token** from [@BotFather](https://t.me/BotFather)

### Prerequisites

```bash
# macOS
brew install terraform awscli jq

# Ubuntu/Debian
sudo apt install terraform awscli jq

# Configure AWS
aws configure
```

---

## Deployment Options

| | Simple | Full |
|--|--------|------|
| **Cost** | ~$18/month | ~$120/month |
| **Best for** | Personal use | Production |
| **Setup** | 5 minutes | 10 minutes |
| **Security** | Good | Maximum |

The wizard asks which one you want.

---

## After Deployment

### 1. Point Your Domain

The setup script shows you the IP or ALB address:

```
# Simple deployment
openclaw.example.com → 1.2.3.4 (A record)

# Full deployment  
openclaw.example.com → abc123.elb.amazonaws.com (CNAME)
```

### 2. Test It

Message your Telegram bot! 🎉

---

## Useful Commands

```bash
# Check status
./scripts/status.sh

# Connect to instance
./scripts/connect.sh

# Update secrets
./scripts/store-secrets.sh

# Set/reset webhook
./scripts/set-webhook.sh <bot-token> <domain>

# Destroy everything
./destroy.sh
```

---

## Manual Deployment

If you prefer to deploy manually:

```bash
cd terraform/simple  # or terraform/full
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars

terraform init
terraform apply

# Then store secrets and start services
# See terraform/simple/README.md or terraform/full/README.md
```

---

## Architecture

### Simple (~$18/month)
```
Internet → EC2 (Caddy TLS) → OpenClaw → Secrets Manager
```

### Full (~$120/month)
```
Internet → WAF → ALB → Private EC2 → VPC Endpoints → Secrets Manager
```

---

## Troubleshooting

### Can't connect to instance
```bash
# Check instance is running
./scripts/status.sh

# Connect via SSM
./scripts/connect.sh
```

### OpenClaw not responding
```bash
# Connect and check logs
./scripts/connect.sh
sudo journalctl -u openclaw -f
sudo systemctl restart openclaw
```

### Webhook not working
```bash
# Re-set webhook
./scripts/set-webhook.sh <bot-token> <domain>

# Check Caddy/ALB
curl -I https://your-domain.com/health
```

---

## Documentation

- [Simple Deployment](terraform/simple/README.md)
- [Full Deployment](terraform/full/README.md)
- [Architecture Details](architecture.md)
- [Security Report](SECURITY-REPORT.md)

---

## License

MIT License - see [LICENSE](LICENSE)
