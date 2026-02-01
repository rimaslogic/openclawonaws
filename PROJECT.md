# OpenClaw on AWS - Project Overview

## Purpose

Provide a secure, production-ready template for deploying OpenClaw AI assistant on AWS infrastructure.

## Goals

- Security-first architecture with encryption at rest and in transit
- Minimal attack surface (no SSH, SSM-only access)
- Infrastructure as Code using Terraform
- Cost-efficient deployment options
- Comprehensive documentation

## Key Security Controls

- ✅ Encryption at rest (KMS-managed)
- ✅ Encryption in transit (TLS 1.3)
- ✅ No SSH access (SSM Session Manager only)
- ✅ Secrets in AWS Secrets Manager
- ✅ IAM least privilege
- ✅ Full audit trail (CloudTrail, VPC Flow Logs)

## Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Project overview and quick start |
| [architecture.md](architecture.md) | Detailed security architecture |
| [implementation-path.md](implementation-path.md) | End-to-end deployment guide |
| [devops-mcp.md](devops-mcp.md) | AI-powered DevOps automation |
| [terraform/README.md](terraform/README.md) | Terraform deployment guide |

## Cost Estimates

| Tier | Monthly Cost |
|------|--------------|
| Full security | ~$73 |
| Budget-conscious | ~$40 |

## Status

🟢 Ready for deployment
