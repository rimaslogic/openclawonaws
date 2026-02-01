# OpenClaw AWS - Full Deployment

Production-grade deployment with maximum security.

## Cost: ~$120-130/month

| Component | Cost |
|-----------|------|
| EC2 t3.small | $15.33 |
| EBS 20GB | $1.60 |
| NAT Gateway | $32.40 |
| ALB | $21.20 |
| VPC Endpoints | $36.50 |
| WAF | $5.00 |
| Secrets Manager | $1.20 |
| KMS | $1.00 |
| CloudWatch | $5.00 |
| **Total** | **~$120** |

## Architecture

```
Internet → WAF → ALB (TLS) → Private Subnet → EC2
                                    ↓
                              NAT Gateway
                                    ↓
                            VPC Endpoints
                                    ↓
                           Secrets Manager
```

## Features

- ✅ WAF with rate limiting & AWS managed rules
- ✅ ALB with deletion protection & access logging
- ✅ Private subnet (EC2 not directly accessible)
- ✅ VPC Endpoints for AWS services
- ✅ Encrypted everything (KMS)
- ✅ 365-day log retention
- ✅ SSM Session Manager (no SSH)
- ✅ IMDSv2 required

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your domain

terraform init
terraform plan
terraform apply
```

## When to use Simple instead

Choose **Simple** if you:
- Are a single user
- Want lowest cost (~$18/month)
- Don't need compliance features
- Are comfortable with EC2 in public subnet
