# CLAUDE.md

TopVNSport DevOps - Infrastructure as Code repository.

## Commands

```bash
# Initialize (run in environment directory)
terraform init

# Format code
terraform fmt -recursive

# Validate
terraform validate

# Plan
terraform plan -var-file="terraform.tfvars"

# Apply (via CI/CD only for staging/prod)
terraform apply -var-file="terraform.tfvars"
```

## Conventions

- All resources must have tags: `project`, `environment`, `managed_by`
- Use modules for reusable infrastructure components
- Environment-specific configs go in `environments/<env>/`
- No hardcoded secrets - use variables or secret manager
- Run `terraform fmt` before committing

## CI/CD

- PR: terraform plan runs automatically
- Merge to main: terraform apply runs for staging
- Prod: manual workflow dispatch with approval
