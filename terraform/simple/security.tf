# Security - Simple Deployment

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for OpenClaw encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-kms"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}"
  target_key_id = aws_kms_key.main.key_id
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for OpenClaw EC2"
  vpc_id      = aws_vpc.main.id

  # HTTPS for webhooks
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP for Let's Encrypt ACME challenge
  ingress {
    description = "HTTP for ACME"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optional SSH (only if ssh_allowed_cidr is set)
  dynamic "ingress" {
    for_each = var.ssh_allowed_cidr != "" ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_allowed_cidr]
    }
  }

  # All outbound
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}
