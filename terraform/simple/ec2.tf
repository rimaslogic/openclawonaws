# EC2 Instance - Simple Deployment with Caddy for TLS

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

# Elastic IP
resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

resource "aws_eip_association" "main" {
  instance_id   = aws_instance.openclaw.id
  allocation_id = aws_eip.main.id
}

# EC2 Instance
resource "aws_instance" "openclaw" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

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
    http_tokens                 = "required"
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

    # Install Caddy (for automatic TLS)
    dnf install -y 'dnf-command(copr)'
    dnf copr enable -y @caddy/caddy
    dnf install -y caddy

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

    # Create Caddyfile for reverse proxy
    cat > /etc/caddy/Caddyfile << 'CADDYFILE'
    ${var.domain_name} {
        reverse_proxy localhost:18789
    }
    CADDYFILE

    # Create startup script
    cat > /home/openclaw/start-openclaw.sh << 'SCRIPT'
    #!/bin/bash
    export ANTHROPIC_API_KEY=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.anthropic_key.name} --query SecretString --output text --region ${var.aws_region})
    export TELEGRAM_BOT_TOKEN=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.telegram_token.name} --query SecretString --output text --region ${var.aws_region})
    export OPENCLAW_GATEWAY_TOKEN=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.gateway_token.name} --query SecretString --output text --region ${var.aws_region})
    exec /home/openclaw/.npm-global/bin/openclaw gateway start
    SCRIPT
    chmod +x /home/openclaw/start-openclaw.sh
    chown openclaw:openclaw /home/openclaw/start-openclaw.sh

    # Create systemd service for OpenClaw
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

    # Enable services
    systemctl daemon-reload
    systemctl enable caddy
    systemctl enable openclaw

    # Signal completion
    echo "OpenClaw installation complete" > /var/log/openclaw-install.log
  EOF
  )

  tags = {
    Name = "${var.project_name}-instance"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
