# Secrets Manager

# Anthropic API Key
resource "aws_secretsmanager_secret" "anthropic_key" {
  name                    = "${var.project_name}/anthropic-api-key"
  description             = "Anthropic API key for Claude"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-anthropic-key"
  }
}

# Telegram Bot Token
resource "aws_secretsmanager_secret" "telegram_token" {
  name                    = "${var.project_name}/telegram-bot-token"
  description             = "Telegram bot token"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-telegram-token"
  }
}

# Gateway Auth Token
resource "aws_secretsmanager_secret" "gateway_token" {
  name                    = "${var.project_name}/gateway-auth-token"
  description             = "OpenClaw gateway authentication token"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-gateway-token"
  }
}

# Note: Secret values must be set manually after deployment:
# aws secretsmanager put-secret-value --secret-id openclaw/anthropic-api-key --secret-string "sk-ant-xxx"
# aws secretsmanager put-secret-value --secret-id openclaw/telegram-bot-token --secret-string "123456:ABC"
# aws secretsmanager put-secret-value --secret-id openclaw/gateway-auth-token --secret-string "$(openssl rand -base64 32)"
