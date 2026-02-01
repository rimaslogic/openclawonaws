# EC2 Instance - Minimal Deployment
# Just like a VPS - configure OpenClaw manually

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
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ebs_volume_size
    encrypted             = true
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
    dnf install -y nodejs git

    # Create openclaw user
    useradd -m -s /bin/bash openclaw

    # Install OpenClaw globally
    npm install -g openclaw

    # Create workspace
    mkdir -p /home/openclaw/.openclaw/workspace
    chown -R openclaw:openclaw /home/openclaw

    # Create systemd service
    cat > /etc/systemd/system/openclaw.service << 'SERVICE'
    [Unit]
    Description=OpenClaw Gateway
    After=network.target

    [Service]
    Type=simple
    User=openclaw
    WorkingDirectory=/home/openclaw
    ExecStart=/usr/bin/openclaw gateway start
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable openclaw

    echo "Ready! Connect via SSM and run: sudo -u openclaw openclaw init" > /var/log/openclaw-install.log
  EOF
  )

  tags = {
    Name = "${var.project_name}-instance"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
