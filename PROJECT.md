# OpenClaw on AWS

## Overview

Deploying and running OpenClaw on AWS infrastructure with security-first approach.

## Status

🟢 Active — Set up 2026-02-01

## Goals

- Secure deployment with encryption at rest and in transit
- Minimal attack surface
- Cost-efficient infrastructure
- Best practices compliance

## Architecture

**See:** [architecture.md](architecture.md)

Two options defined:
- **Full security** (~$72/month) — Private subnet, NAT Gateway, ALB, WAF
- **Budget-conscious** (~$22-40/month) — Public subnet with hardened security

## Key Security Controls

- ✅ Encryption at rest (KMS-managed)
- ✅ Encryption in transit (TLS 1.3)
- ✅ No SSH access (SSM Session Manager only)
- ✅ Secrets in AWS Secrets Manager
- ✅ IAM least privilege
- ✅ Full audit trail (CloudTrail, VPC Flow Logs)

## Credentials / Secrets

| Secret | Storage |
|--------|---------|
| Anthropic API key | AWS Secrets Manager |
| Telegram bot token | AWS Secrets Manager |
| Gateway auth token | AWS Secrets Manager |

## Cost Estimates

| Tier | Monthly Cost |
|------|--------------|
| Full security | ~$72 |
| Budget-conscious | ~$22-40 |

## Documentation

| Document | Description |
|----------|-------------|
| [architecture.md](architecture.md) | Security-focused AWS architecture |
| [implementation-path.md](implementation-path.md) | End-to-end deployment guide |
| [devops-mcp.md](devops-mcp.md) | AI-powered DevOps automation with AWS MCP servers |

## Next Steps

- [ ] Choose architecture tier (full ~$72/mo vs budget ~$22-40/mo)
- [ ] Set up AWS account + MFA
- [x] ~~Install Kiro CLI or configure mcporter for Terraform generation~~ ✅ mcporter configured
- [ ] Configure AWS CLI credentials
- [ ] Generate Terraform scripts using MCP servers
- [ ] Define backup procedures
- [ ] Create operational runbook

## Notes

*(Running notes, decisions, issues)*
