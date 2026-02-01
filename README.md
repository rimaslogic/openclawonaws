# OpenClaw on AWS

Deploy [OpenClaw](https://github.com/openclaw/openclaw) AI assistant on AWS with Terraform.

## 🚀 Two Deployment Options

| | Simple | Full |
|--|--------|------|
| **Cost** | ~$18/month | ~$120/month |
| **Best for** | Single user | Production/Teams |
| **Setup** | 30 minutes | 1 hour |
| **Security** | Good | Maximum |

### Quick Start

```bash
# Clone the repo
git clone https://github.com/rimaslogic/openclawonaws.git
cd openclawonaws/terraform

# Choose your deployment:
cd simple    # For single user (~$18/month)
# OR
cd full      # For production (~$120/month)

# Deploy
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your domain
terraform init
terraform apply
```

---

## Option 1: Simple (~$18/month)

Perfect for personal use with a single Telegram account.

```
Internet → EC2 (Caddy + Let's Encrypt) → OpenClaw
```

**Includes:**
- EC2 t3.micro with Elastic IP
- Automatic HTTPS via Caddy
- Encrypted EBS storage
- Secrets Manager
- SSM access (no SSH needed)

[📖 Simple Deployment Guide](terraform/simple/README.md)

---

## Option 2: Full (~$120/month)

Production-grade with maximum security.

```
Internet → WAF → ALB → Private Subnet → EC2
                              ↓
                        VPC Endpoints
```

**Includes everything in Simple, plus:**
- WAF with rate limiting
- Application Load Balancer
- Private subnet isolation
- VPC Endpoints for AWS services
- 365-day log retention
- ALB access logging

[📖 Full Deployment Guide](terraform/full/README.md)

---

## Documentation

| Document | Description |
|----------|-------------|
| [terraform/README.md](terraform/README.md) | Deployment comparison & decision guide |
| [architecture.md](architecture.md) | Full security architecture |
| [implementation-path.md](implementation-path.md) | Step-by-step guide |
| [devops-mcp.md](devops-mcp.md) | AI-powered DevOps automation |
| [SECURITY-REPORT.md](SECURITY-REPORT.md) | Checkov scan results |

---

## Prerequisites

- AWS account
- Domain name (for HTTPS)
- Terraform >= 1.5.0
- AWS CLI configured

---

## Security Features

Both deployments include:
- ✅ Encrypted storage (KMS)
- ✅ Secrets in AWS Secrets Manager
- ✅ IMDSv2 required
- ✅ SSM Session Manager (no SSH)

Full deployment adds:
- ✅ WAF protection
- ✅ Private subnet
- ✅ VPC Endpoints
- ✅ ALB with access logging

---

## License

MIT License - see [LICENSE](LICENSE)
