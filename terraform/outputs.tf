# Outputs - Minimal Deployment

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.openclaw.id
}

output "public_ip" {
  description = "Public IP (may change on restart)"
  value       = aws_instance.openclaw.public_ip
}

output "connect_command" {
  description = "Connect via SSM"
  value       = "aws ssm start-session --target ${aws_instance.openclaw.id}"
}

output "next_steps" {
  value = <<-EOT

    ╔════════════════════════════════════════════════════════════╗
    ║                   SETUP COMPLETE! 🎉                       ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║  1. Connect to your instance:                              ║
    ║                                                            ║
    ║     aws ssm start-session --target ${aws_instance.openclaw.id}
    ║                                                            ║
    ║  2. Initialize OpenClaw (enter your Telegram token):       ║
    ║                                                            ║
    ║     sudo -u openclaw openclaw init                         ║
    ║                                                            ║
    ║  3. Start OpenClaw:                                        ║
    ║                                                            ║
    ║     sudo systemctl start openclaw                          ║
    ║                                                            ║
    ║  4. Message your Telegram bot!                             ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
  EOT
}
