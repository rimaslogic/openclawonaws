# Security Scan Report

**Tool:** Checkov v3.2.500 (via AWS Terraform MCP Server)
**Date:** 2026-02-01
**Scanner:** aws-terraform.RunCheckovScan

## Summary

| Status | Count |
|--------|-------|
| ✅ Passed | 112 |
| ❌ Failed | 18 |
| ⏭️ Skipped | 0 |
| **Resources** | 54 |

---

## Findings by Priority

### 🔴 High Priority (Should Fix)

| ID | Resource | Issue | Fix |
|----|----------|-------|-----|
| CKV2_AWS_28 | `aws_lb.main` | ALB not protected by WAF | Add AWS WAF web ACL |
| CKV_AWS_150 | `aws_lb.main` | Deletion protection disabled | Set `enable_deletion_protection = true` |
| CKV_AWS_91 | `aws_lb.main` | No access logging | Add `access_logs` block with S3 bucket |
| CKV2_AWS_12 | `aws_vpc.main` | Default security group not restricted | Add `aws_default_security_group` resource |

### 🟡 Medium Priority (Recommended)

| ID | Resource | Issue | Fix |
|----|----------|-------|-----|
| CKV_AWS_126 | `aws_instance.openclaw` | No detailed monitoring | Add `monitoring = true` |
| CKV_AWS_135 | `aws_instance.openclaw` | EBS not optimized | Add `ebs_optimized = true` |
| CKV_AWS_338 | CloudWatch Log Groups | Only 30-day retention | Increase `retention_in_days = 365` |
| CKV_AWS_382 | `aws_security_group.vpc_endpoints` | Unrestricted egress | Restrict to required ports only |
| CKV_AWS_355 | `aws_iam_role_policy.flow_logs` | IAM uses "*" resource | Scope to specific log group ARN |
| CKV_AWS_18 | `aws_s3_bucket.backup` | No access logging | Add logging bucket |

### 🟢 Low Priority (Nice to Have)

| ID | Resource | Issue | Notes |
|----|----------|-------|-------|
| CKV2_AWS_57 | Secrets Manager | No auto-rotation | API keys don't support rotation |
| CKV2_AWS_62 | `aws_s3_bucket.backup` | No event notifications | Optional for backup bucket |
| CKV_AWS_144 | `aws_s3_bucket.backup` | No cross-region replication | Cost vs DR tradeoff |
| CKV2_AWS_19 | `aws_eip.nat` | EIP not attached to EC2 | False positive (NAT Gateway) |

---

## Detailed Recommendations

### 1. Add WAF Protection (High)

```hcl
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
```

**Cost impact:** ~$5-10/month

### 2. Enable ALB Access Logging (High)

```hcl
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"
}

# Add to aws_lb.main:
access_logs {
  bucket  = aws_s3_bucket.alb_logs.id
  prefix  = "alb"
  enabled = true
}
```

### 3. Enable EC2 Detailed Monitoring (Medium)

```hcl
# Add to aws_instance.openclaw:
monitoring    = true
ebs_optimized = true
```

**Cost impact:** ~$2/month for detailed monitoring

### 4. Restrict Default Security Group (Medium)

```hcl
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress or egress rules = deny all
  tags = {
    Name = "${var.project_name}-default-sg-restricted"
  }
}
```

### 5. Increase Log Retention (Medium)

```hcl
# Change in both CloudWatch log groups:
retention_in_days = 365
```

**Cost impact:** Higher CloudWatch storage costs

### 6. Restrict VPC Endpoint Egress (Medium)

```hcl
# In aws_security_group.vpc_endpoints:
egress {
  description = "HTTPS to AWS services"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr]
}
```

### 7. Scope IAM Policy (Medium)

```hcl
# In aws_iam_role_policy.flow_logs:
Resource = aws_cloudwatch_log_group.flow_logs.arn
```

---

## Findings Not Requiring Action

| ID | Reason |
|----|--------|
| CKV2_AWS_57 (Secrets rotation) | API keys from external providers (Anthropic, Telegram) don't support automatic rotation |
| CKV2_AWS_19 (EIP unattached) | False positive - EIP is attached to NAT Gateway, not EC2 |
| CKV_AWS_144 (S3 cross-region) | Cost consideration for personal deployment; acceptable risk |

---

## Cost Impact Summary

| Fix | Additional Monthly Cost |
|-----|------------------------|
| WAF | ~$5-10 |
| Detailed monitoring | ~$2 |
| Extended log retention | Variable (~$5-20) |
| ALB access logs (storage) | ~$1-5 |
| **Total** | **~$13-37/month** |

---

## Recommended Actions

1. **Immediate:** Enable ALB deletion protection
2. **Before production:** Add WAF protection
3. **For compliance:** Increase log retention to 365 days
4. **For security:** Restrict VPC endpoint and default security groups
5. **Optional:** Add S3 access logging and event notifications

---

## Re-scan Command

After fixes, re-run:
```bash
mcporter call aws-terraform.RunCheckovScan working_directory=./terraform
```
