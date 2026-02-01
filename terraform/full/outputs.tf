# Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.openclaw.id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "domain_name" {
  description = "Domain name for OpenClaw"
  value       = var.domain_name
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.main.arn
}

output "acm_certificate_status" {
  description = "ACM certificate status"
  value       = aws_acm_certificate.main.status
}

output "acm_validation_records" {
  description = "DNS records for certificate validation (if not using Route53)"
  value = var.route53_zone_id == "" ? {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : null
}

output "secrets_arns" {
  description = "Secrets Manager ARNs"
  value = {
    anthropic_key = aws_secretsmanager_secret.anthropic_key.arn
    telegram_token = aws_secretsmanager_secret.telegram_token.arn
    gateway_token  = aws_secretsmanager_secret.gateway_token.arn
  }
}

output "backup_bucket" {
  description = "S3 backup bucket name"
  value       = aws_s3_bucket.backup.id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.main.arn
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "alb_logs_bucket" {
  description = "ALB access logs bucket"
  value       = aws_s3_bucket.alb_logs.id
}

output "ssm_connect_command" {
  description = "Command to connect to instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.openclaw.id}"
}

output "post_deployment_steps" {
  description = "Steps to complete after deployment"
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════╗
    ║                  POST-DEPLOYMENT STEPS                       ║
    ╠══════════════════════════════════════════════════════════════╣
    ║                                                              ║
    ║  1. Validate ACM certificate (if not using Route53):        ║
    ║     - Add DNS validation record shown in output             ║
    ║     - Wait for certificate status: ISSUED                   ║
    ║                                                              ║
    ║  2. Store secrets:                                          ║
    ║     aws secretsmanager put-secret-value \                   ║
    ║       --secret-id ${aws_secretsmanager_secret.anthropic_key.name} \
    ║       --secret-string "sk-ant-xxx"                          ║
    ║                                                              ║
    ║     aws secretsmanager put-secret-value \                   ║
    ║       --secret-id ${aws_secretsmanager_secret.telegram_token.name} \
    ║       --secret-string "123456:ABC"                          ║
    ║                                                              ║
    ║     aws secretsmanager put-secret-value \                   ║
    ║       --secret-id ${aws_secretsmanager_secret.gateway_token.name} \
    ║       --secret-string "$(openssl rand -base64 32)"          ║
    ║                                                              ║
    ║  3. Connect and start OpenClaw:                             ║
    ║     aws ssm start-session --target ${aws_instance.openclaw.id}
    ║     sudo systemctl start openclaw                           ║
    ║     sudo systemctl status openclaw                          ║
    ║                                                              ║
    ║  4. Set Telegram webhook:                                   ║
    ║     curl "https://api.telegram.org/bot<TOKEN>/setWebhook    ║
    ║       ?url=https://${var.domain_name}/telegram-webhook"     ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
  EOT
}
