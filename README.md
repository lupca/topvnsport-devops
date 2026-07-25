# TopVNSport DevOps

Infrastructure as Code (IaC) repository for deploying TopVNSport system using Terraform and GitHub Actions CI/CD.

## Structure

```
.
├── environments/           # Environment-specific configurations
│   ├── dev/               # Development environment
│   ├── staging/           # Staging environment
│   └── prod/              # Production environment
├── modules/               # Reusable Terraform modules
├── scripts/               # Helper scripts
└── .github/workflows/     # GitHub Actions CI/CD
```

## Usage

### Prerequisites

- Terraform >= 1.0
- Cloud provider CLI configured (AWS/GCP/Azure)
- GitHub repository secrets configured

### Local Development

```bash
# Initialize Terraform
cd environments/dev
terraform init

# Plan changes
terraform plan

# Apply changes (use CI/CD for staging/prod)
terraform apply
```

### CI/CD Pipeline

- **Pull Request**: Runs `terraform plan` and posts output as PR comment
- **Merge to main**: Runs `terraform apply` for the target environment

## Environments

| Environment | Branch/Trigger | Auto-apply |
|:------------|:---------------|:-----------|
| dev         | PR to main     | No (plan only) |
| staging     | merge to main  | Yes |
| prod        | manual trigger | Yes (with approval) |

## Security

- All secrets managed via GitHub Secrets or external secret manager
- No credentials hardcoded in code
- State files stored in remote backend with encryption
