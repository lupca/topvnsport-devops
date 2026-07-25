# TopVNSport Infrastructure as Code

Terraform IaC cho hạ tầng TopVNSport trên AWS.

## Quick Start

```bash
# Clone
git clone git@github.com:lupca/topvnsport-devops.git
cd topvnsport-devops

# AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Deploy
cd environments/prod
terraform init
terraform plan
terraform apply
```

## Documentation

| Tài liệu | Mô tả |
|----------|-------|
| [Getting Started](docs/getting-started.md) | Cài đặt, cấu trúc thư mục, bắt đầu |
| [Tạo môi trường mới](docs/create-new-environment.md) | Hướng dẫn tạo dev/staging/env mới |
| [CI/CD Setup](docs/cicd-setup.md) | Setup GitHub Actions, secrets, variables |
| [Xử lý sự cố](docs/troubleshooting.md) | Debug các lỗi thường gặp |
| [Production Infrastructure](docs/prod-infrastructure.md) | Chi tiết hạ tầng prod |

## Cấu trúc

```
topvnsport-devops/
├── modules/           # EC2, RDS, S3, VPC
├── environments/      # prod, staging, dev
├── docs/              # Documentation
└── .github/workflows/ # CI/CD
```

## Environments

| Env | Region | Resources |
|-----|--------|-----------|
| prod | us-east-1 | Dùng có sẵn (imported) |
| staging | us-east-1 | Tạo mới |
| dev | us-east-1 | Tạo mới |

## Key Concept: Tạo mới vs Dùng có sẵn

```hcl
# Tạo mới (dev/staging)
ec2_existing_sg_id = ""

# Dùng có sẵn (prod)
ec2_existing_sg_id = "sg-0051b179f57a7ad15"
```

Chi tiết: [docs/create-new-environment.md](docs/create-new-environment.md)

## CI/CD

```bash
# Trigger thủ công
gh workflow run terraform.yml -f environment=prod -f action=plan

# Xem kết quả
gh run list --workflow=terraform.yml
```

Chi tiết: [docs/cicd-setup.md](docs/cicd-setup.md)

## Production

| Resource | Endpoint |
|----------|----------|
| EC2 | `52.203.250.214` |
| RDS | `topvnsport-db.cluster-xxx.rds.amazonaws.com` |
| S3 | `s3://topvnsport-assets` |

Chi tiết: [docs/prod-infrastructure.md](docs/prod-infrastructure.md)
