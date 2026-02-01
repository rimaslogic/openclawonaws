# Variables for Simple OpenClaw Deployment

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "openclaw"
}

variable "domain_name" {
  description = "Domain name for HTTPS (e.g., openclaw.example.com)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 20
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH (set to your IP for debugging, empty to disable)"
  type        = string
  default     = ""
}
