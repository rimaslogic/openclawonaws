# AWS Setup Guide

## Prerequisites

- [ ] AWS account with admin access
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.5.0 installed
- [ ] Domain name for HTTPS (e.g., openclaw.yourdomain.com)

## AWS CLI Installation

### macOS
```bash
brew install awscli
```

### Linux
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Configure
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format
```

## Terraform Installation

### macOS
```bash
brew install terraform
```

### Linux
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Verify
```bash
terraform --version
```

## IAM Permissions Required

Your AWS user/role needs these permissions:
- EC2: Full access
- VPC: Full access
- ELB: Full access
- S3: Full access
- Secrets Manager: Full access
- KMS: Full access
- IAM: Create roles and policies
- CloudWatch: Create log groups
- ACM: Request certificates
- Route53: Manage DNS (optional)

Or use the `AdministratorAccess` managed policy for simplicity.

## Monitoring Setup

After deployment, set up CloudWatch alarms:

1. **CPU Utilization** > 80%
2. **Memory Utilization** > 80%
3. **Disk Utilization** > 80%
4. **ALB 5xx errors** > 10/minute
5. **Target health** unhealthy count > 0

## Troubleshooting

### Cannot connect via SSM
- Verify EC2 instance has the IAM role attached
- Check VPC endpoints are created
- Ensure security group allows HTTPS outbound

### ALB health check failing
- Check security group allows ALB to EC2 on port 18789
- Verify OpenClaw service is running
- Check /health endpoint responds

### Secrets not loading
- Verify IAM role has Secrets Manager permissions
- Check secret names match the configuration
- Ensure KMS key policy allows the EC2 role

### Certificate not validating
- Add DNS validation record (shown in Terraform output)
- Wait 5-30 minutes for DNS propagation
- Check certificate status in ACM console
