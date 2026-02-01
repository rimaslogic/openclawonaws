# OpenClaw AWS Terraform

Choose your deployment option:

## 🚀 Quick Comparison

| Feature | Simple | Full |
|---------|--------|------|
| **Cost** | ~$18/month | ~$120/month |
| **Best for** | Single user | Teams/Production |
| **TLS** | Caddy (Let's Encrypt) | ALB + ACM |
| **Network** | Public subnet | Private subnet |
| **WAF** | ❌ | ✅ |
| **High Availability** | ❌ | ✅ |
| **VPC Endpoints** | ❌ | ✅ |
| **Setup time** | ~30 min | ~1 hour |

---

## Option 1: Simple (~$18/month)

**Best for:** Single Telegram user, personal use, cost-conscious

```bash
cd simple
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

[📖 Simple README](simple/README.md)

---

## Option 2: Full (~$120/month)

**Best for:** Production, multiple users, compliance requirements

```bash
cd full
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

[📖 Full README](full/README.md)

---

## Decision Guide

```
                    ┌─────────────────────┐
                    │  How many users?    │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
         Just me         2-5 users        Enterprise
              │                │                │
              ▼                ▼                ▼
         ┌────────┐      ┌─────────┐     ┌─────────┐
         │ SIMPLE │      │  FULL   │     │  FULL   │
         │ $18/mo │      │ $120/mo │     │ + HA/DR │
         └────────┘      └─────────┘     └─────────┘
```

## Prerequisites (Both Options)

1. AWS account with admin access
2. AWS CLI configured (`aws configure`)
3. Terraform >= 1.5.0
4. A domain name

## After Deployment

Both options require:
1. Point your domain to the IP/ALB
2. Store secrets in AWS Secrets Manager
3. Start the OpenClaw service
4. Set Telegram webhook

See the README in each folder for detailed steps.
