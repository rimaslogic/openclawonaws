# OpenClaw AWS Terraform

Secure deployment of OpenClaw on AWS.

## Security Features

- ✅ **No SSH access** — SSM Session Manager only
- ✅ **Encrypted EBS** — KMS-managed encryption at rest
- ✅ **Encrypted secrets** — AWS Secrets Manager with KMS
- ✅ **Private subnet** — EC2 not directly accessible
- ✅ **HTTPS only** — TLS 1.3 via ALB
- ✅ **VPC Flow Logs** — Network audit trail
- ✅ **IMDSv2 required** — Metadata service hardening
- ✅ **VPC Endpoints** — Private access to AWS services

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider configuration |
| `variables.tf` | Input variables |
| `vpc.tf` | VPC, subnets, NAT, VPC endpoints |
| `security.tf` | Security groups, KMS key |
| `iam.tf` | IAM roles and policies |
| `secrets.tf` | Secrets Manager resources |
| `ec2.tf` | EC2 instance with user data |
| `alb.tf` | Application Load Balancer, ACM |
| `s3.tf` | Backup bucket |
| `outputs.tf` | Output values |

## Prerequisites

1. AWS CLI configured (`aws configure`)
2. Terraform >= 1.5.0
3. A domain name for HTTPS

## Deployment

```bash
# 1. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Initialize Terraform
terraform init

# 3. Review plan
terraform plan

# 4. Apply
terraform apply

# 5. Follow post-deployment steps in output
```

## Post-Deployment

After `terraform apply`:

1. **Validate ACM certificate** (if not using Route53)
   - Add DNS validation record from output
   - Wait for certificate status: ISSUED

2. **Store secrets**
   ```bash
   aws secretsmanager put-secret-value \
     --secret-id openclaw/anthropic-api-key \
     --secret-string "sk-ant-xxx"

   aws secretsmanager put-secret-value \
     --secret-id openclaw/telegram-bot-token \
     --secret-string "123456:ABC"

   aws secretsmanager put-secret-value \
     --secret-id openclaw/gateway-auth-token \
     --secret-string "$(openssl rand -base64 32)"
   ```

3. **Start OpenClaw**
   ```bash
   aws ssm start-session --target <instance-id>
   sudo systemctl start openclaw
   sudo systemctl status openclaw
   ```

4. **Set Telegram webhook**
   ```bash
   curl "https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://your-domain/telegram-webhook"
   ```

## Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| EC2 t3.small | ~$15 |
| EBS 20GB gp3 | ~$2 |
| NAT Gateway | ~$32 |
| ALB | ~$16 |
| Secrets Manager | ~$1 |
| VPC Endpoints | ~$7 |
| **Total** | **~$73/month** |

### Budget Option

Set `enable_nat_gateway = false` to save ~$32/month. 
The EC2 can still reach the internet via VPC endpoints for AWS services
and the ALB for inbound traffic, but outbound to non-AWS services
(Anthropic API, Telegram API) will require the NAT Gateway.

## Destroy

```bash
terraform destroy
```

⚠️ This will delete all resources including backups. 
Export important data first.
