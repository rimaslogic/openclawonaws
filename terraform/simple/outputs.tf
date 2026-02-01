# Outputs - Simple Deployment

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.openclaw.id
}

output "public_ip" {
  description = "Elastic IP address"
  value       = aws_eip.main.public_ip
}

output "domain_name" {
  description = "Domain name for OpenClaw"
  value       = var.domain_name
}

output "secrets_arns" {
  description = "Secrets Manager ARNs"
  value = {
    anthropic_key  = aws_secretsmanager_secret.anthropic_key.arn
    telegram_token = aws_secretsmanager_secret.telegram_token.arn
    gateway_token  = aws_secretsmanager_secret.gateway_token.arn
  }
}

output "ssm_connect_command" {
  description = "Command to connect via SSM"
  value       = "aws ssm start-session --target ${aws_instance.openclaw.id}"
}

output "post_deployment_steps" {
  description = "Steps to complete after deployment"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════╗
    ║                  POST-DEPLOYMENT STEPS                       ║
    ╠══════════════════════════════════════════════════════════════╣
    ║                                                              ║
    ║  1. Point your domain to the Elastic IP:                    ║
    ║     ${var.domain_name} → ${aws_eip.main.public_ip}          ║
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
    ║  3. Start services:                                         ║
    ║     aws ssm start-session --target ${aws_instance.openclaw.id}
    ║     sudo systemctl start caddy                              ║
    ║     sudo systemctl start openclaw                           ║
    ║                                                              ║
    ║  4. Set Telegram webhook:                                   ║
    ║     curl "https://api.telegram.org/bot<TOKEN>/setWebhook    ║
    ║       ?url=https://${var.domain_name}/telegram-webhook"     ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
  EOT
}
