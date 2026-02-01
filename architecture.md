# OpenClaw AWS Architecture

## Design Principles

1. **Security first** — Zero trust, minimal attack surface
2. **Encryption everywhere** — At rest and in transit
3. **Least privilege** — IAM roles with minimal permissions
4. **Cost efficiency** — Minimal viable secure infrastructure

---

## Architecture Overview

```
                                    ┌─────────────────────────────────────────────────────────┐
                                    │                        AWS Cloud                         │
                                    │                                                          │
    ┌──────────┐                    │  ┌─────────────────────────────────────────────────┐   │
    │ Telegram │──── HTTPS ─────────┼──│              Application Load Balancer           │   │
    │   API    │                    │  │              (TLS termination, WAF)              │   │
    └──────────┘                    │  └─────────────────────┬───────────────────────────┘   │
                                    │                        │                                │
    ┌──────────┐                    │                        ▼                                │
    │ Anthropic│◄── HTTPS ──────────┼────────────┐   ┌──────────────┐                        │
    │   API    │                    │            │   │   Private    │                        │
    └──────────┘                    │            │   │   Subnet     │                        │
                                    │            │   │              │                        │
                                    │            │   │  ┌────────┐  │   ┌─────────────────┐  │
                                    │            └───┼──│   EC2  │──┼───│   NAT Gateway   │  │
                                    │                │  │OpenClaw│  │   │   (outbound)    │  │
                                    │                │  └───┬────┘  │   └─────────────────┘  │
                                    │                │      │       │                        │
                                    │                │      ▼       │                        │
                                    │                │  ┌────────┐  │                        │
                                    │                │  │  EBS   │  │                        │
                                    │                │  │(encrypted)│                       │
                                    │                │  └────────┘  │                        │
                                    │                └──────────────┘                        │
                                    │                                                          │
                                    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
                                    │  │   Secrets   │  │     S3      │  │   CloudWatch    │  │
                                    │  │   Manager   │  │  (backups)  │  │   (logs/alarms) │  │
                                    │  │ (encrypted) │  │ (encrypted) │  │                 │  │
                                    │  └─────────────┘  └─────────────┘  └─────────────────┘  │
                                    │                                                          │
                                    └─────────────────────────────────────────────────────────┘
```

---

## Components

### 1. Network Layer

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| **VPC** | 10.0.0.0/16, DNS enabled | Isolated network |
| **Public Subnet** | 10.0.1.0/24 | ALB, NAT Gateway |
| **Private Subnet** | 10.0.10.0/24 | EC2 instance |
| **NAT Gateway** | In public subnet | Secure outbound traffic |
| **Internet Gateway** | Attached to VPC | ALB inbound access |

### 2. Compute

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| **EC2** | t3.small (2 vCPU, 2GB RAM) | OpenClaw gateway |
| **AMI** | Amazon Linux 2023 (hardened) | Minimal OS |
| **EBS** | 20GB gp3, encrypted (AES-256) | Persistent storage |

### 3. Load Balancer & Ingress

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| **ALB** | HTTPS only (TLS 1.3) | Ingress for webhooks |
| **ACM Certificate** | Auto-renewed | TLS termination |
| **WAF** | Rate limiting, geo-blocking | DDoS protection |
| **Target Group** | Health checks on /health | EC2 routing |

### 4. Security

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| **Security Group (ALB)** | Inbound: 443 from 0.0.0.0/0 | Public HTTPS only |
| **Security Group (EC2)** | Inbound: 443 from ALB SG only | No direct access |
| **IAM Role** | Minimal: SSM, Secrets, S3, CloudWatch | Least privilege |
| **SSM Session Manager** | Enabled | No SSH, audited access |
| **KMS** | Customer-managed key | Encryption key control |

### 5. Secrets Management

| Secret | Storage | Access |
|--------|---------|--------|
| Anthropic API key | Secrets Manager | EC2 IAM role |
| Telegram bot token | Secrets Manager | EC2 IAM role |
| Gateway auth token | Secrets Manager | EC2 IAM role |

### 6. Backup & Recovery

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| **S3 Bucket** | Versioned, encrypted, lifecycle policy | Config/session backups |
| **EBS Snapshots** | Daily, 7-day retention | Disaster recovery |

### 7. Monitoring & Audit

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| **CloudWatch Logs** | Encrypted, 30-day retention | Application logs |
| **CloudWatch Alarms** | CPU, memory, errors | Alerting |
| **CloudTrail** | All regions, S3 storage | API audit trail |
| **VPC Flow Logs** | Enabled | Network audit |

---

## Security Controls

### Encryption at Rest

| Resource | Encryption | Key Management |
|----------|------------|----------------|
| EBS volumes | AES-256 | KMS (CMK) |
| S3 buckets | AES-256 | KMS (CMK) |
| Secrets Manager | AES-256 | KMS (CMK) |
| CloudWatch Logs | AES-256 | KMS (CMK) |
| RDS (if used) | AES-256 | KMS (CMK) |

### Encryption in Transit

| Connection | Protocol | Notes |
|------------|----------|-------|
| Client → ALB | TLS 1.3 | ACM certificate |
| ALB → EC2 | TLS 1.2+ | Internal cert |
| EC2 → Anthropic | TLS 1.3 | Outbound HTTPS |
| EC2 → Secrets Manager | TLS 1.2+ | AWS endpoints |

### Access Control

| Access Type | Method | Audit |
|-------------|--------|-------|
| Instance access | SSM Session Manager | CloudTrail |
| AWS Console | IAM + MFA required | CloudTrail |
| API access | IAM roles (no keys on instance) | CloudTrail |

### Network Security

- ✅ No public IP on EC2
- ✅ No SSH port (22) open anywhere
- ✅ Outbound via NAT Gateway only
- ✅ Security groups: explicit allow only
- ✅ VPC Flow Logs enabled

---

## Cost Estimate (Minimal)

### Monthly Costs (eu-central-1)

| Service | Specification | Est. Cost/Month |
|---------|---------------|-----------------|
| EC2 | t3.small, on-demand | $15.33 |
| EBS | 20GB gp3 | $1.60 |
| NAT Gateway | Per hour + data | $32.40 + data |
| ALB | Per hour + LCU | $16.20 + LCU |
| Secrets Manager | 3 secrets | $1.20 |
| S3 | 1GB + requests | $0.50 |
| CloudWatch | Logs + alarms | $3.00 |
| KMS | 1 CMK + requests | $1.00 |
| **Total (minimal)** | | **~$72/month** |

### Cost Optimization Options

| Option | Savings | Trade-off |
|--------|---------|-----------|
| Reserved Instance (1yr) | -30% on EC2 | Commitment |
| Spot Instance | -60% on EC2 | Interruption risk |
| Remove NAT Gateway* | -$32/month | Reduced security |
| Use t3.micro | -$7/month | Less headroom |

*Alternative to NAT Gateway: VPC endpoints for AWS services + EC2 in public subnet with strict SGs (less secure but cheaper)

### Budget-Conscious Secure Option (~$40/month)

If $72/month is too high:

```
EC2 t3.micro (public subnet)     $7.59
EBS 20GB gp3                     $1.60
Elastic IP                       $3.65
Secrets Manager (3 secrets)      $1.20
S3 (backups)                     $0.50
CloudWatch                       $3.00
WAF (basic)                      $5.00
CloudTrail                       Free tier
─────────────────────────────────────────
Total                           ~$22/month + data transfer
```

Trade-offs:
- EC2 in public subnet (mitigated by strict security groups)
- No ALB (direct access to EC2, use nginx for TLS)
- No NAT Gateway (direct outbound from EC2)

---

## Recommendations

### For Maximum Security (Recommended)

Use the full architecture (~$72/month):
- Private subnet + NAT Gateway
- ALB with WAF
- No direct instance access

### For Budget-Conscious

Use simplified architecture (~$22-40/month):
- Public subnet with hardened security groups
- nginx reverse proxy with Let's Encrypt
- Same encryption and secrets management

---

## Next Steps

1. [ ] Decide on architecture tier (full vs budget)
2. [ ] Set up AWS account with MFA
3. [ ] Create Terraform/CloudFormation templates
4. [ ] Define backup/recovery procedures
5. [ ] Document operational runbook
