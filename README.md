# OpenClaw on AWS

Secure, production-ready deployment of [OpenClaw](https://github.com/openclaw/openclaw) AI assistant on AWS infrastructure.

## Features

- 🔒 **Security-first architecture** — No SSH, SSM-only access, encrypted everything
- 🏗️ **Infrastructure as Code** — Complete Terraform configuration
- 📖 **Comprehensive documentation** — Architecture, implementation guide, DevOps automation
- 💰 **Cost-optimized** — Options for ~$73/month (full) or ~$40/month (budget)

## Quick Start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

See [terraform/README.md](terraform/README.md) for detailed deployment instructions.

## Documentation

| Document | Description |
|----------|-------------|
| [architecture.md](architecture.md) | Security-focused AWS architecture design |
| [implementation-path.md](implementation-path.md) | Step-by-step deployment guide |
| [devops-mcp.md](devops-mcp.md) | AI-powered DevOps automation with AWS MCP servers |
| [terraform/README.md](terraform/README.md) | Terraform deployment guide |

## Architecture Overview

```
Internet → ALB (HTTPS/TLS 1.3) → Private Subnet → EC2 (OpenClaw)
                                                      ↓
                                               Secrets Manager
                                               CloudWatch Logs
                                               S3 Backups
```

## Security Controls

| Control | Implementation |
|---------|----------------|
| No SSH access | SSM Session Manager only |
| Encryption at rest | KMS-managed (EBS, S3, Secrets) |
| Encryption in transit | TLS 1.3 via ALB |
| Network isolation | Private subnet, VPC endpoints |
| Secrets management | AWS Secrets Manager |
| Audit logging | VPC Flow Logs, CloudTrail |
| Instance hardening | IMDSv2 required |

## Cost Estimate

| Tier | Monthly Cost | Notes |
|------|--------------|-------|
| Full | ~$73 | Private subnet, NAT Gateway, ALB |
| Budget | ~$40 | Disable NAT Gateway |

## Prerequisites

- AWS account with admin access
- Domain name for HTTPS
- Terraform >= 1.5.0
- AWS CLI configured

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please read the architecture documentation before submitting changes.
