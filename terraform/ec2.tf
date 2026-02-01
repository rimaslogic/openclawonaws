# EC2 Instance

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "openclaw" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # No SSH key - SSM only!
  # key_name = ... # Intentionally omitted

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ebs_volume_size
    encrypted             = true
    kms_key_id            = aws_kms_key.main.arn
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 required
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Update system
    dnf update -y

    # Install Node.js 22
    curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
    dnf install -y nodejs

    # Install Docker
    dnf install -y docker
    systemctl enable docker
    systemctl start docker

    # Create openclaw user
    useradd -m -s /bin/bash openclaw
    usermod -aG docker openclaw

    # Install OpenClaw
    su - openclaw -c "npm install -g openclaw"

    # Create config directory
    mkdir -p /home/openclaw/.openclaw
    chown -R openclaw:openclaw /home/openclaw/.openclaw

    # Create startup script that fetches secrets
    cat > /home/openclaw/start-openclaw.sh << 'SCRIPT'
    #!/bin/bash
    export ANTHROPIC_API_KEY=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.anthropic_key.name} --query SecretString --output text)
    export TELEGRAM_BOT_TOKEN=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.telegram_token.name} --query SecretString --output text)
    export OPENCLAW_GATEWAY_TOKEN=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.gateway_token.name} --query SecretString --output text)
    exec /home/openclaw/.npm-global/bin/openclaw gateway start
    SCRIPT
    chmod +x /home/openclaw/start-openclaw.sh
    chown openclaw:openclaw /home/openclaw/start-openclaw.sh

    # Create systemd service
    cat > /etc/systemd/system/openclaw.service << 'SERVICE'
    [Unit]
    Description=OpenClaw Gateway
    After=network.target docker.service
    Requires=docker.service

    [Service]
    Type=simple
    User=openclaw
    Environment=NODE_ENV=production
    ExecStart=/home/openclaw/start-openclaw.sh
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Enable service (don't start yet - secrets need to be populated first)
    systemctl daemon-reload
    systemctl enable openclaw

    # Signal completion
    echo "OpenClaw installation complete" > /var/log/openclaw-install.log
  EOF
  )

  tags = {
    Name = "${var.project_name}-instance"
  }

  lifecycle {
    ignore_changes = [ami] # Don't force replacement on AMI updates
  }
}

# CloudWatch Log Group for OpenClaw
resource "aws_cloudwatch_log_group" "openclaw" {
  name              = "/aws/openclaw/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-logs"
  }
}
