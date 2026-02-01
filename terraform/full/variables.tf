# Variables for OpenClaw deployment

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "openclaw"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 20
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for ALB (e.g., openclaw.example.com)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (optional, for automatic DNS)"
  type        = string
  default     = ""
}

# Budget option: disable NAT Gateway (less secure but cheaper)
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (disable for budget option)"
  type        = bool
  default     = true
}

# Log retention
variable "log_retention_days" {
  description = "CloudWatch log retention in days (365 recommended for compliance)"
  type        = number
  default     = 365
}
