# OpenClaw on AWS

Deploy [OpenClaw](https://github.com/openclaw/openclaw) on AWS. Just like a VPS.

## Cost: ~$10/month

| Component | Cost |
|-----------|------|
| EC2 t3.micro | $7.59 |
| EBS 20GB | $1.60 |
| **Total** | **~$10** |

## Prerequisites

```bash
# Install
brew install terraform awscli  # macOS
# or: apt install terraform awscli  # Ubuntu

# Configure AWS
aws configure
```

## Deploy

```bash
git clone https://github.com/rimaslogic/openclawonaws.git
cd openclawonaws/terraform
terraform init
terraform apply
```

## Setup

```bash
# Connect to instance
aws ssm start-session --target <instance-id>

# Configure OpenClaw (enter your Telegram token)
sudo -u openclaw openclaw init

# Start
sudo systemctl start openclaw

# Done! Message your Telegram bot 🎉
```

## Useful Commands

```bash
# Connect
aws ssm start-session --target <instance-id>

# View logs
sudo journalctl -u openclaw -f

# Restart
sudo systemctl restart openclaw

# Destroy
terraform destroy
```

## Architecture

```
EC2 (polls) → Telegram API
    (calls) → Anthropic API
```

No inbound traffic. No domain needed. Polling mode.

## License

MIT
