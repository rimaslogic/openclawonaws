# DevOps MCP Integration

Based on: [Transform DevOps practice with Kiro AI-powered agents](https://aws.amazon.com/blogs/publicsector/transform-devops-practice-with-kiro-ai-powered-agents/)

## Overview

AWS provides **Model Context Protocol (MCP) servers** that can automate DevOps tasks using AI agents. These can be integrated with OpenClaw or used via Kiro CLI to manage our AWS infrastructure.

---

## AWS MCP Servers (Available)

| MCP Server | Purpose | Package |
|------------|---------|---------|
| **Core** | AWS CLI operations, resource discovery | `awslabs.core-mcp-server` |
| **Documentation** | AWS docs search & reference | `awslabs.aws-documentation-mcp-server` |
| **Pricing** | Cost estimates & analysis | `awslabs.aws-pricing-mcp-server` |
| **Diagram** | Architecture diagram generation | `awslabs.aws-diagram-mcp-server` |
| **Terraform** | IaC generation & validation | `awslabs.terraform-mcp-server` |
| **EKS** | Kubernetes cluster management | `awslabs.eks-mcp-server` |

Source: [github.com/awslabs/mcp](https://github.com/awslabs/mcp)

---

## Option 1: Use Kiro CLI (Standalone)

Kiro is AWS's agentic AI CLI that uses these MCP servers natively.

### Installation

```bash
curl -fsSL https://cli.kiro.dev/install | bash
kiro-cli login  # Use AWS Builder ID
```

### Create DevOps Agent

```bash
mkdir -p .kiro/agents

cat > .kiro/agents/devops-agent.json << 'EOF'
{
  "name": "devops-agent",
  "description": "DevOps automation agent for AWS infrastructure management",
  "prompt": "You are an expert DevOps specialist focusing on AWS infrastructure as code. You are highly knowledgeable in AWS services and strictly adhere to best architectural practices and security recommendations.",
  "mcpServers": {
    "awslabs.core-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.core-mcp-server@latest"],
      "disabled": false
    },
    "awslabs.aws-documentation-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.aws-documentation-mcp-server@latest"],
      "disabled": false
    },
    "awslabs.aws-pricing-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.aws-pricing-mcp-server@latest"],
      "disabled": false
    },
    "awslabs.terraform-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.terraform-mcp-server@latest"],
      "disabled": false
    }
  },
  "tools": ["*"],
  "toolsSettings": {
    "execute_bash": { "autoAllowReadonly": true },
    "use_aws": { "autoAllowReadonly": true }
  }
}
EOF
```

### Use Cases

```bash
kiro-cli chat --agent devops-agent

# Then in chat:
> Describe my AWS infrastructure in eu-central-1
> Create Terraform script for OpenClaw deployment with ALB, EC2, and Secrets Manager
> Review the Terraform plan and show estimated costs
> Validate security group rules follow best practices
```

---

## Option 2: Integrate MCP with OpenClaw ✅ CONFIGURED

OpenClaw supports MCP servers via the `mcporter` skill.

### Status: INSTALLED

✅ uv/uvx installed (`~/.local/bin`)
✅ mcporter configured (`config/mcporter.json`)
✅ All 6 AWS MCP servers added

### Configured Servers

```bash
mcporter config list
```

| Server | Package | Status |
|--------|---------|--------|
| `aws-core` | awslabs.core-mcp-server | ✅ Ready |
| `aws-docs` | awslabs.aws-documentation-mcp-server | ✅ Ready |
| `aws-pricing` | awslabs.aws-pricing-mcp-server | ✅ Ready |
| `aws-diagram` | awslabs.aws-diagram-mcp-server | ✅ Ready |
| `aws-terraform` | awslabs.terraform-mcp-server | ✅ Ready |
| `aws-eks` | awslabs.eks-mcp-server | ✅ Ready |

### Usage Examples

```bash
# List available tools from a server
mcporter list aws-terraform --schema

# Call a specific tool
mcporter call aws-terraform.ExecuteTerraformCommand \
  command=plan \
  working_directory=./infrastructure

# Get AWS documentation
mcporter call aws-docs.search query="VPC security best practices"

# Get pricing estimates
mcporter call aws-pricing.get_pricing service=ec2 region=eu-central-1
```

---

## Benefits for OpenClaw AWS Project

| Task | MCP Server | Benefit |
|------|------------|---------|
| Generate Terraform | `terraform-mcp-server` | IaC from natural language |
| Cost estimates | `pricing-mcp-server` | Real-time cost analysis |
| Validate architecture | `core-mcp-server` | Best practices check |
| Find documentation | `documentation-mcp-server` | Quick AWS reference |
| Create diagrams | `diagram-mcp-server` | Visual architecture |

---

## Example: Generate OpenClaw Infrastructure

Using Kiro or OpenClaw with MCP:

```
Prompt: Create Terraform scripts for a secure OpenClaw deployment with:
- VPC with private subnet
- EC2 t3.small with encrypted EBS
- ALB with TLS termination
- Secrets Manager for API keys
- CloudWatch logging
- No SSH access, SSM only
Follow AWS security best practices.
```

The MCP servers can:
1. Generate complete Terraform code
2. Validate against best practices
3. Estimate monthly costs
4. Create architecture diagram

---

## Recommended Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. Design Phase                                            │
│     • Use pricing-mcp for cost estimates                    │
│     • Use diagram-mcp for architecture visualization        │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Development Phase                                       │
│     • Use terraform-mcp to generate IaC                     │
│     • Use documentation-mcp for reference                   │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Validation Phase                                        │
│     • Use core-mcp to check existing resources              │
│     • Validate Terraform plans                              │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Deployment Phase                                        │
│     • Apply Terraform with agent assistance                 │
│     • Verify with core-mcp                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Next Steps

- [ ] Install Kiro CLI locally for Terraform generation
- [ ] Or configure MCP servers in OpenClaw via mcporter
- [ ] Use MCP to generate production-ready Terraform scripts
- [ ] Validate cost estimates before deployment

---

## References

- [AWS MCP Servers](https://github.com/awslabs/mcp)
- [Kiro Documentation](https://kiro.dev/docs/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [OpenClaw mcporter skill](/home/clawd/.npm-global/lib/node_modules/openclaw/skills/mcporter/SKILL.md)
