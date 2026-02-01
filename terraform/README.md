# Terraform

```bash
terraform init
terraform apply
```

## After Deploy

1. Connect: `aws ssm start-session --target <instance-id>`
2. Configure: `sudo -u openclaw openclaw init`
3. Start: `sudo systemctl start openclaw`
4. Message your Telegram bot!

## Destroy

```bash
terraform destroy
```
